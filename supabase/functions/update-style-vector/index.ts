import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface InteractionRequest {
  user_id: string;
  interaction_type: "like" | "dislike" | "skip" | "wear" | "save" | "edit_tag";
  item_ids?: string[];
  outfit_data?: Record<string, unknown>;
  context?: {
    field_changed?: string;
    old_value?: string;
    new_value?: string;
    feedback_type?: string;
  };
}

// Interaction weights for style vector updates
const INTERACTION_WEIGHTS: Record<string, number> = {
  like: 0.5,
  dislike: -0.5,
  skip: -0.1,
  wear: 1.0,
  save: 0.7,
  edit_tag: 2.0,
};

// Learning rate decay factor
const ALPHA = 0.95;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const body: InteractionRequest = await req.json();
    const { user_id, interaction_type, item_ids, context } = body;

    if (!user_id || !interaction_type) {
      throw new Error("Missing user_id or interaction_type");
    }

    console.log(`Recording interaction: ${interaction_type} for user ${user_id}`);

    // Step 1: Log the Interaction
    await supabase.from("user_interactions").insert({
      user_id,
      item_id: item_ids?.[0] || null,
      outfit_ids: item_ids,
      interaction_type,
      interaction_weight: INTERACTION_WEIGHTS[interaction_type] || 0,
      context: context || {}
    });

    // Step 2: Handle Tag Corrections (High-Value Learning)
    if (interaction_type === "edit_tag" && context?.field_changed && item_ids?.[0]) {
      await supabase.from("tag_corrections").insert({
        user_id,
        item_id: item_ids[0],
        field_name: context.field_changed,
        original_value: context.old_value,
        corrected_value: context.new_value
      });

      // Update vibe preferences if user corrected a vibe
      if (context.field_changed === "vibe" || context.field_changed === "style_bucket") {
        await updateVibePreferences(supabase, user_id, context.old_value, context.new_value);
      }
    }

    // Step 3: Update User Style Vector
    if (item_ids && item_ids.length > 0) {
      const { data: items } = await supabase
        .from("wardrobe_items")
        .select("id, embedding")
        .in("id", item_ids);

      if (items && items.some((i: { embedding?: number[] }) => i.embedding)) {
        // Get current user style vector
        const { data: currentStyle } = await supabase
          .from("user_style_vectors")
          .select("*")
          .eq("user_id", user_id)
          .single();

        // Calculate new style vector
        const weight = INTERACTION_WEIGHTS[interaction_type] || 0;
        const newVector = calculateUpdatedStyleVector(
          currentStyle?.style_vector,
          items.filter((i: { embedding?: number[] }) => i.embedding).map((i: { embedding: number[] }) => i.embedding),
          weight
        );

        // Upsert user style vector
        await supabase
          .from("user_style_vectors")
          .upsert({
            user_id,
            style_vector: newVector,
            interaction_count: (currentStyle?.interaction_count || 0) + 1,
            last_updated: new Date().toISOString(),
            preferences: currentStyle?.preferences || {},
            preferred_vibes: currentStyle?.preferred_vibes || [],
            avoided_vibes: currentStyle?.avoided_vibes || []
          }, {
            onConflict: "user_id"
          });

        console.log(`Style vector updated for user ${user_id}`);
      }
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Style update error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// Update style vector using weighted moving average
function calculateUpdatedStyleVector(
  currentVector: number[] | null,
  itemVectors: number[][],
  weight: number
): number[] {
  const vectorSize = 512;

  // Initialize if no current vector
  if (!currentVector || currentVector.length !== vectorSize) {
    currentVector = new Array(vectorSize).fill(0);
  }

  // Average the item vectors
  const avgItemVector = new Array(vectorSize).fill(0);
  for (const vec of itemVectors) {
    if (vec && vec.length === vectorSize) {
      for (let i = 0; i < vectorSize; i++) {
        avgItemVector[i] += vec[i] / itemVectors.length;
      }
    }
  }

  // Apply weighted update: U_new = α * U_old + (1-α) * w * I_avg
  const newVector = new Array(vectorSize);
  const effectiveWeight = Math.abs(weight) * (1 - ALPHA);
  const sign = weight >= 0 ? 1 : -1;

  for (let i = 0; i < vectorSize; i++) {
    newVector[i] = ALPHA * currentVector[i] + effectiveWeight * sign * avgItemVector[i];
  }

  // Normalize the vector
  const magnitude = Math.sqrt(newVector.reduce((sum: number, val: number) => sum + val * val, 0));
  if (magnitude > 0) {
    for (let i = 0; i < vectorSize; i++) {
      newVector[i] /= magnitude;
    }
  }

  return newVector;
}

// Update vibe preferences based on corrections
async function updateVibePreferences(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  oldVibe: string | undefined,
  newVibe: string | undefined
) {
  const { data: currentStyle } = await supabase
    .from("user_style_vectors")
    .select("preferred_vibes, avoided_vibes")
    .eq("user_id", userId)
    .single();

  const preferredVibes = new Set<string>(currentStyle?.preferred_vibes || []);
  const avoidedVibes = new Set<string>(currentStyle?.avoided_vibes || []);

  // If user changed FROM a vibe, they might not prefer it
  if (oldVibe) {
    preferredVibes.delete(oldVibe);
  }

  // If user changed TO a vibe, they prefer it
  if (newVibe) {
    preferredVibes.add(newVibe);
    avoidedVibes.delete(newVibe);
  }

  await supabase
    .from("user_style_vectors")
    .update({
      preferred_vibes: Array.from(preferredVibes),
      avoided_vibes: Array.from(avoidedVibes)
    })
    .eq("user_id", userId);
}
