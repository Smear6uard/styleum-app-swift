import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Action types and their corresponding stat fields and achievement categories
const ACTION_CONFIG: Record<string, { statField: string; categories: string[] }> = {
  add_item: { statField: "total_items_added", categories: ["wardrobe"] },
  generate_outfit: { statField: "total_outfits_generated", categories: ["outfits"] },
  wear_outfit: { statField: "total_outfits_worn", categories: ["worn"] },
  save_outfit: { statField: "total_outfits_generated", categories: ["outfits"] }, // Same as generate for now
  share_outfit: { statField: "total_outfits_shared", categories: ["social"] },
  update_streak: { statField: "", categories: ["streaks"] }, // Streak uses value param directly
};

interface UpdateRequest {
  user_id: string;
  action_type: "add_item" | "generate_outfit" | "wear_outfit" | "save_outfit" | "share_outfit" | "update_streak";
  value?: number; // For streak count
}

interface Achievement {
  id: string;
  title: string;
  description: string;
  category: string;
  rarity: string;
  target_progress: number;
  icon_name: string;
  xp_reward: number;
}

interface UserStats {
  user_id: string;
  total_items_added: number;
  total_outfits_generated: number;
  total_outfits_worn: number;
  total_outfits_shared: number;
  total_style_points: number;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const body: UpdateRequest = await req.json();
    const { user_id, action_type, value } = body;

    if (!user_id || !action_type) {
      throw new Error("Missing user_id or action_type");
    }

    const config = ACTION_CONFIG[action_type];
    if (!config) {
      throw new Error(`Invalid action_type: ${action_type}`);
    }

    console.log(`[update-achievements] Processing ${action_type} for user ${user_id}`);

    // ============================================================
    // Step 1: Upsert user_stats - create with defaults if doesn't exist
    // ============================================================

    const { data: existingStats } = await supabase
      .from("user_stats")
      .select("*")
      .eq("user_id", user_id)
      .single();

    let stats: UserStats;

    if (!existingStats) {
      // First-time user - create stats row with defaults
      console.log(`[update-achievements] Creating user_stats for new user`);
      const { data: newStats, error: insertError } = await supabase
        .from("user_stats")
        .insert({
          user_id,
          total_items_added: 0,
          total_outfits_generated: 0,
          total_outfits_worn: 0,
          total_outfits_shared: 0,
          total_style_points: 0,
        })
        .select()
        .single();

      if (insertError) {
        console.error("[update-achievements] Failed to create user_stats:", insertError);
        throw new Error("Failed to initialize user stats");
      }
      stats = newStats;
    } else {
      stats = existingStats;
    }

    // ============================================================
    // Step 2: Increment the relevant stat (skip for streak actions)
    // ============================================================

    if (action_type !== "update_streak" && config.statField) {
      const currentValue = (stats as Record<string, number>)[config.statField] || 0;
      const newValue = currentValue + 1;

      const { error: updateError } = await supabase
        .from("user_stats")
        .update({
          [config.statField]: newValue,
          updated_at: new Date().toISOString()
        })
        .eq("user_id", user_id);

      if (updateError) {
        console.error("[update-achievements] Failed to update stats:", updateError);
        throw new Error("Failed to update user stats");
      }

      // Update local stats object
      (stats as Record<string, number>)[config.statField] = newValue;
      console.log(`[update-achievements] Updated ${config.statField}: ${currentValue} → ${newValue}`);
    }

    // ============================================================
    // Step 3: Get all achievement definitions for relevant categories
    // ============================================================

    const { data: achievements, error: achievementsError } = await supabase
      .from("achievement_definitions")
      .select("*")
      .in("category", config.categories)
      .order("sort_order");

    if (achievementsError) {
      console.error("[update-achievements] Failed to fetch achievements:", achievementsError);
      throw new Error("Failed to fetch achievement definitions");
    }

    console.log(`[update-achievements] Found ${achievements?.length || 0} achievements in categories: ${config.categories.join(", ")}`);

    // ============================================================
    // Step 4: Check and update progress for each achievement
    // ============================================================

    const newlyUnlocked: Achievement[] = [];

    for (const achievement of (achievements || []) as Achievement[]) {
      // Determine current progress based on action type
      let currentProgress: number;

      if (action_type === "update_streak") {
        // For streaks, use the value parameter (current streak count)
        currentProgress = value || 0;
      } else {
        // For other actions, use the stat value
        currentProgress = (stats as Record<string, number>)[config.statField] || 0;
      }

      // Get existing user_achievement row
      const { data: existingProgress } = await supabase
        .from("user_achievements")
        .select("*")
        .eq("user_id", user_id)
        .eq("achievement_id", achievement.id)
        .single();

      const wasAlreadyUnlocked = existingProgress?.unlocked_at != null;
      const isNowUnlocked = currentProgress >= achievement.target_progress;

      if (!existingProgress) {
        // First-time: create user_achievement row
        const insertData: Record<string, unknown> = {
          user_id,
          achievement_id: achievement.id,
          current_progress: currentProgress,
          updated_at: new Date().toISOString(),
        };

        // Check if newly unlocked
        if (isNowUnlocked) {
          insertData.unlocked_at = new Date().toISOString();
          newlyUnlocked.push(achievement);
          console.log(`[update-achievements] 🎉 Unlocked: ${achievement.title}`);
        }

        await supabase
          .from("user_achievements")
          .insert(insertData);
      } else {
        // Update existing row
        const updateData: Record<string, unknown> = {
          current_progress: currentProgress,
          updated_at: new Date().toISOString(),
        };

        // Check if newly unlocked (wasn't before, is now)
        if (!wasAlreadyUnlocked && isNowUnlocked) {
          updateData.unlocked_at = new Date().toISOString();
          newlyUnlocked.push(achievement);
          console.log(`[update-achievements] 🎉 Unlocked: ${achievement.title}`);
        }

        await supabase
          .from("user_achievements")
          .update(updateData)
          .eq("user_id", user_id)
          .eq("achievement_id", achievement.id);
      }
    }

    // ============================================================
    // Step 5: Return result
    // ============================================================

    console.log(`[update-achievements] Complete. Newly unlocked: ${newlyUnlocked.length}`);

    return new Response(
      JSON.stringify({
        success: true,
        stats,
        newly_unlocked: newlyUnlocked.map((a) => ({
          id: a.id,
          title: a.title,
          description: a.description,
          rarity: a.rarity,
          icon_name: a.icon_name,
          xp_reward: a.xp_reward,
        })),
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[update-achievements] Error:", error);
    return new Response(
      JSON.stringify({ success: false, error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
