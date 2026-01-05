import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callOpenRouter, MODELS, extractJSON } from "../_shared/openrouter.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RegenerateRequest {
  user_id: string;
  current_outfit_ids: string[];
  feedback: "more_casual" | "more_formal" | "more_bold" | "more_classic" | "different_colors" | "different_vibe";
  occasion?: string;
  specific_request?: string;
}

interface WardrobeItem {
  id: string;
  item_name: string;
  category: string;
  subcategory: string;
  primary_color: string;
  color_hex: string;
  formality: number;
  style_bucket: string;
  vibe_scores: Record<string, number>;
  dense_caption: string;
  times_worn: number;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const body: RegenerateRequest = await req.json();
    const { user_id, current_outfit_ids, feedback, occasion = "casual", specific_request } = body;

    if (!user_id || !current_outfit_ids || !feedback) {
      throw new Error("Missing required fields");
    }

    console.log(`Regenerating outfit for user: ${user_id}, feedback: ${feedback}`);

    // Fetch user's wardrobe
    const { data: wardrobeItems, error: wardrobeError } = await supabase
      .from("wardrobe_items")
      .select("*")
      .eq("user_id", user_id);

    if (wardrobeError) throw wardrobeError;

    // Get current outfit items to understand what to change
    const currentItems = wardrobeItems?.filter((item: WardrobeItem) =>
      current_outfit_ids.includes(item.id)
    ) || [];

    // Build feedback instruction
    const feedbackInstructions: Record<string, string> = {
      more_casual: "Make it MORE CASUAL - choose relaxed fits, casual fabrics, lower formality items. Avoid anything structured or dressy.",
      more_formal: "Make it MORE FORMAL - choose structured pieces, refined fabrics, higher formality items. Think polished and put-together.",
      more_bold: "Make it MORE BOLD - use bolder colors, interesting patterns, statement pieces. Don't be safe.",
      more_classic: "Make it MORE CLASSIC - use timeless pieces, neutral colors, traditional combinations. Think elegant simplicity.",
      different_colors: `Use COMPLETELY DIFFERENT COLORS than the current outfit which has: ${currentItems.map((i: WardrobeItem) => i.primary_color).join(", ")}. Choose a new color palette.`,
      different_vibe: `Choose a DIFFERENT AESTHETIC/VIBE than the current outfit. Current vibes: ${currentItems.flatMap((i: WardrobeItem) => Object.keys(i.vibe_scores || {})).join(", ")}`,
    };

    const feedbackInstruction = feedbackInstructions[feedback] || feedback;

    // Prepare wardrobe summary (excluding current items for variety)
    const availableItems = wardrobeItems?.filter((item: WardrobeItem) =>
      !current_outfit_ids.includes(item.id)
    ) || [];

    const wardrobeSummary = availableItems.map((item: WardrobeItem) => ({
      id: item.id,
      name: item.item_name || `${item.primary_color} ${item.subcategory}`,
      category: item.category,
      color: item.primary_color,
      color_hex: item.color_hex,
      formality: item.formality,
      style: item.style_bucket,
      vibes: Object.keys(item.vibe_scores || {}),
      description: item.dense_caption,
      times_worn: item.times_worn || 0
    }));

    // Also include current items in case AI wants to keep some
    const currentItemsSummary = currentItems.map((item: WardrobeItem) => ({
      id: item.id,
      name: item.item_name,
      category: item.category,
      color: item.primary_color,
      note: "FROM CURRENT OUTFIT - can keep if it fits the new direction"
    }));

    const prompt = `You are a fashion stylist. The user wants a DIFFERENT outfit based on their feedback.

USER FEEDBACK: ${feedbackInstruction}
${specific_request ? `SPECIFIC REQUEST: ${specific_request}` : ""}

OCCASION: ${occasion}

CURRENT OUTFIT (user wants to change from this):
${JSON.stringify(currentItemsSummary, null, 2)}

AVAILABLE ITEMS (prioritize these for variety):
${JSON.stringify(wardrobeSummary, null, 2)}

Create ONE new outfit that directly addresses the feedback. You may keep 1-2 items from the current outfit if they fit the new direction, but prioritize fresh items.

Return JSON:
{
  "wardrobe_item_ids": ["id1", "id2", "id3"],
  "score": 85,
  "occasion": "${occasion}",
  "headline": "Punchy 6-8 word description",
  "why_it_works": "2-3 sentences explaining how this addresses the feedback",
  "style_notes": "One styling tip",
  "color_harmony": "Color coordination description",
  "vibe": "Primary aesthetic",
  "items": [
    {"id": "id1", "role": "top"},
    {"id": "id2", "role": "bottom"},
    {"id": "id3", "role": "shoes"}
  ],
  "changes_made": "Brief explanation of what changed from the original"
}

Return ONLY valid JSON.`;

    const response = await callOpenRouter(
      MODELS.GEMINI_FLASH_LITE,
      [{ role: "user", content: prompt }],
      { temperature: 0.8, max_tokens: 1024 }
    );

    const responseText = response.choices[0]?.message?.content || "";
    const outfit = extractJSON(responseText);

    // Validate item IDs
    const validIds = new Set(wardrobeItems?.map((i: WardrobeItem) => i.id) || []);
    const outfitData = outfit as { wardrobe_item_ids?: string[] };
    if (!outfitData.wardrobe_item_ids?.every((id: string) => validIds.has(id))) {
      throw new Error("Invalid item IDs in response");
    }

    // Log feedback for learning
    await supabase.from("outfit_feedback").insert({
      user_id,
      original_outfit_ids: current_outfit_ids,
      feedback_type: feedback,
      new_outfit_ids: outfitData.wardrobe_item_ids,
      was_accepted: null,
      created_at: new Date().toISOString()
    });

    // Trigger style vector update (dislike for current outfit)
    await supabase.functions.invoke("update-style-vector", {
      body: {
        user_id,
        interaction_type: "dislike",
        item_ids: current_outfit_ids,
        context: { feedback_type: feedback }
      }
    }).catch((e: Error) => console.error("Style update failed:", e));

    console.log(`Regenerated outfit with feedback: ${feedback}`);

    return new Response(
      JSON.stringify({ success: true, outfit }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Regenerate error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
