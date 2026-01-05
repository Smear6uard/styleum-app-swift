import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface StreakRequest {
  user_id: string;
}

interface UserStreak {
  user_id: string;
  current_streak: number;
  longest_streak: number;
  last_active_date: string | null;
  total_days_active: number;
}

interface UnlockedAchievement {
  id: string;
  title: string;
  description: string;
  rarity: string;
  icon_name: string;
  xp_reward: number;
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

    const body: StreakRequest = await req.json();
    const { user_id } = body;

    if (!user_id) {
      throw new Error("Missing user_id");
    }

    console.log(`[update-streak] Processing streak for user ${user_id}`);

    // Get today's date in UTC (YYYY-MM-DD format)
    const today = new Date();
    const todayStr = today.toISOString().split("T")[0];

    // Calculate yesterday's date
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split("T")[0];

    console.log(`[update-streak] Today: ${todayStr}, Yesterday: ${yesterdayStr}`);

    // ============================================================
    // Step 1: Get or create user_streaks row
    // ============================================================

    const { data: existingStreak } = await supabase
      .from("user_streaks")
      .select("*")
      .eq("user_id", user_id)
      .single();

    let streak: UserStreak;
    let streakIncreased = false;
    let streakReset = false;

    if (!existingStreak) {
      // First-time user - create streak row
      console.log(`[update-streak] Creating streak for new user`);

      const { data: newStreak, error: insertError } = await supabase
        .from("user_streaks")
        .insert({
          user_id,
          current_streak: 1,
          longest_streak: 1,
          last_active_date: todayStr,
          total_days_active: 1,
        })
        .select()
        .single();

      if (insertError) {
        console.error("[update-streak] Failed to create streak:", insertError);
        throw new Error("Failed to initialize streak");
      }

      streak = newStreak;
      streakIncreased = true;
      console.log(`[update-streak] First day! Streak: 1`);
    } else {
      streak = existingStreak;
      const lastActiveDate = streak.last_active_date;

      // ============================================================
      // Step 2: Check last_active_date and update streak
      // ============================================================

      if (lastActiveDate === todayStr) {
        // Already active today - no change needed
        console.log(`[update-streak] Already active today. Streak: ${streak.current_streak}`);
      } else if (lastActiveDate === yesterdayStr) {
        // Active yesterday - increment streak
        const newStreak = streak.current_streak + 1;
        const newLongest = Math.max(streak.longest_streak, newStreak);
        const newTotalDays = streak.total_days_active + 1;

        const { error: updateError } = await supabase
          .from("user_streaks")
          .update({
            current_streak: newStreak,
            longest_streak: newLongest,
            last_active_date: todayStr,
            total_days_active: newTotalDays,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", user_id);

        if (updateError) {
          console.error("[update-streak] Failed to update streak:", updateError);
          throw new Error("Failed to update streak");
        }

        streak.current_streak = newStreak;
        streak.longest_streak = newLongest;
        streak.last_active_date = todayStr;
        streak.total_days_active = newTotalDays;
        streakIncreased = true;

        console.log(`[update-streak] Streak continued! ${streak.current_streak - 1} → ${streak.current_streak}`);
      } else {
        // Streak broken - reset to 1
        const newTotalDays = streak.total_days_active + 1;

        const { error: updateError } = await supabase
          .from("user_streaks")
          .update({
            current_streak: 1,
            last_active_date: todayStr,
            total_days_active: newTotalDays,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", user_id);

        if (updateError) {
          console.error("[update-streak] Failed to reset streak:", updateError);
          throw new Error("Failed to reset streak");
        }

        console.log(`[update-streak] Streak reset! ${streak.current_streak} → 1`);
        streak.current_streak = 1;
        streak.last_active_date = todayStr;
        streak.total_days_active = newTotalDays;
        streakReset = true;
      }
    }

    // ============================================================
    // Step 3: Check for streak achievements
    // ============================================================

    let newlyUnlocked: UnlockedAchievement[] = [];

    // Only check achievements if streak changed (increased or first day)
    if (streakIncreased || streakReset) {
      console.log(`[update-streak] Checking streak achievements for streak: ${streak.current_streak}`);

      // Call update-achievements to check streak achievements
      const { data: achievementResult, error: achievementError } = await supabase.functions
        .invoke("update-achievements", {
          body: {
            user_id,
            action_type: "update_streak",
            value: streak.current_streak,
          },
        });

      if (achievementError) {
        console.error("[update-streak] Failed to check achievements:", achievementError);
        // Don't throw - streak update succeeded, achievement check is secondary
      } else if (achievementResult?.newly_unlocked) {
        newlyUnlocked = achievementResult.newly_unlocked;
        console.log(`[update-streak] Unlocked ${newlyUnlocked.length} achievements`);
      }
    }

    // ============================================================
    // Step 4: Return result
    // ============================================================

    console.log(`[update-streak] Complete. Current: ${streak.current_streak}, Longest: ${streak.longest_streak}`);

    return new Response(
      JSON.stringify({
        success: true,
        current_streak: streak.current_streak,
        longest_streak: streak.longest_streak,
        total_days_active: streak.total_days_active,
        last_active_date: streak.last_active_date,
        streak_increased: streakIncreased,
        streak_reset: streakReset,
        newly_unlocked: newlyUnlocked,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[update-streak] Error:", error);
    return new Response(
      JSON.stringify({ success: false, error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
