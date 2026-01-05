import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callOpenRouter, MODELS, extractJSON } from "../_shared/openrouter.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface GenerateRequest {
  user_id?: string;
  occasion?: string;
  weather?: { temp: number; condition: string };
  boldness?: number;
  color_preference?: string;
  avoid_items?: string[];
}

interface WardrobeItem {
  id: string;
  item_name: string;
  category: string;
  subcategory: string;
  primary_color: string;
  color_hex: string;
  material: string;
  fit: string;
  formality: number;
  style_bucket: string;
  seasonality: string[];
  occasions: string[];
  vibe_scores: Record<string, number>;
  dense_caption: string;
  era: string;
  times_worn: number;
  is_favorite: boolean;
  embedding: number[];
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

    // Get user from auth token or request body
    const authHeader = req.headers.get("Authorization");
    const body: GenerateRequest = await req.json().catch(() => ({}));
    let userId: string;

    if (authHeader && !authHeader.includes("eyJpc3MiOiJzdXBhYmFzZSI")) {
      // This is a user JWT token, not the anon key
      const { data: { user }, error } = await supabase.auth.getUser(
        authHeader.replace("Bearer ", "")
      );
      if (error || !user) throw new Error("Unauthorized");
      userId = user.id;
    } else if (body.user_id) {
      // Use user_id from request body
      userId = body.user_id;
    } else {
      throw new Error("Missing user_id or valid auth token");
    }
    const occasion = body.occasion || "casual";
    const weather = body.weather || { temp: 70, condition: "clear" };
    const boldness = body.boldness || 3;
    const avoidItems = body.avoid_items || [];

    console.log(`Generating outfits for user: ${userId}, occasion: ${occasion}`);

    // Fetch user's wardrobe
    let wardrobeQuery = supabase
      .from("wardrobe_items")
      .select("*")
      .eq("user_id", userId);

    if (avoidItems.length > 0) {
      wardrobeQuery = wardrobeQuery.not("id", "in", `(${avoidItems.join(",")})`);
    }

    const { data: wardrobeItems, error: wardrobeError } = await wardrobeQuery;

    if (wardrobeError) throw wardrobeError;

    if (!wardrobeItems || wardrobeItems.length < 3) {
      return new Response(
        JSON.stringify({
          error: "not_enough_items",
          message: "Add at least 3 items to your wardrobe"
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch user style vector
    const { data: styleData } = await supabase
      .from("user_style_vectors")
      .select("*")
      .eq("user_id", userId)
      .single();

    const preferredVibes = styleData?.preferred_vibes || [];
    const avoidedVibes = styleData?.avoided_vibes || [];

    // Fetch recent feedback for context
    const { data: recentFeedback } = await supabase
      .from("outfit_feedback")
      .select("*")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .limit(10);

    const feedbackContext = recentFeedback?.length
      ? `\nRECENT USER FEEDBACK:
${recentFeedback.map((f: { feedback_type: string; was_accepted: boolean | null }) =>
  `- ${f.feedback_type}: ${f.was_accepted ? "accepted" : f.was_accepted === false ? "rejected" : "pending"}`
).join("\n")}`
      : "";

    // Categorize wardrobe
    const itemsByCategory = categorizeItems(wardrobeItems);

    const hasTops = (itemsByCategory.top?.length || 0) > 0;
    const hasBottoms = (itemsByCategory.bottom?.length || 0) > 0;
    const hasShoes = (itemsByCategory.shoes?.length || 0) > 0;
    const hasDresses = (itemsByCategory.dress?.length || 0) > 0;

    if (!((hasTops && hasBottoms) || hasDresses) || !hasShoes) {
      return new Response(
        JSON.stringify({
          error: "missing_essentials",
          message: "You need: (1 top + 1 bottom) OR (1 dress) + shoes"
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Prepare wardrobe summary for AI
    const wardrobeSummary = wardrobeItems.map((item: WardrobeItem) => ({
      id: item.id,
      name: item.item_name || `${item.primary_color} ${item.subcategory}`,
      category: item.category,
      subcategory: item.subcategory,
      color: item.primary_color,
      color_hex: item.color_hex,
      material: item.material,
      fit: item.fit,
      formality: item.formality,
      style: item.style_bucket,
      era: item.era,
      seasons: item.seasonality || [],
      occasions: item.occasions || [],
      vibes: Object.entries(item.vibe_scores || {})
        .filter(([_, score]) => (score as number) > 0.5)
        .map(([vibe]) => vibe),
      description: item.dense_caption,
      times_worn: item.times_worn || 0,
      is_favorite: item.is_favorite
    }));

    const currentSeason = getCurrentSeason();
    const timeOfDay = getTimeOfDay();

    // AI Outfit Generation
    const systemPrompt = `You are an elite fashion stylist with expertise in color theory, silhouette balance, and cultural aesthetics. You understand vintage fashion, contemporary trends, and subculture styles.

Your task is to create COHESIVE, STYLISH outfits that:
1. Have intentional color harmony (complementary, analogous, monochromatic, or strategic contrast)
2. Balance proportions (slim top + relaxed bottom, or vice versa)
3. Match formality levels appropriately
4. Consider seasonal appropriateness
5. Respect the user's style preferences
6. Favor less-worn items for variety

NEVER suggest mismatched formality (e.g., formal blazer with gym shorts).
ALWAYS explain the color story and why items work together.`;

    const userPrompt = `Create 4 complete outfit combinations from this wardrobe.

CONTEXT:
- Occasion: ${occasion}
- Weather: ${weather.temp}°F, ${weather.condition}
- Season: ${currentSeason}
- Time of day: ${timeOfDay}
- Boldness preference: ${boldness}/5 (1=classic/safe, 5=bold/experimental)
${preferredVibes.length ? `- User PREFERS these vibes: ${preferredVibes.join(", ")}` : ""}
${avoidedVibes.length ? `- User AVOIDS these vibes: ${avoidedVibes.join(", ")}` : ""}
${feedbackContext}

WARDROBE (${wardrobeItems.length} items):
${JSON.stringify(wardrobeSummary, null, 2)}

OUTFIT REQUIREMENTS:
- Each outfit MUST have: 1 top (or dress) + 1 bottom (if not dress) + 1 shoes
- Outerwear: optional but recommended for ${weather.temp < 65 ? "cooler" : "layering"} weather
- Accessories: optional but can elevate the look
- Each outfit should be DISTINCTLY DIFFERENT in vibe/color story

SCORING RUBRIC (out of 100):
- Color Harmony: 25 points
- Occasion Match: 25 points
- Style Cohesion: 25 points
- Seasonal Fit: 15 points
- Freshness: 10 points

Return a JSON array with exactly 4 outfits:
[
  {
    "wardrobe_item_ids": ["id1", "id2", "id3"],
    "score": 85,
    "occasion": "${occasion}",
    "headline": "A punchy 6-8 word description like 'Effortlessly chic for evening drinks'",
    "why_it_works": "2-3 sentence explanation mentioning specific items, colors, and why they complement each other",
    "style_notes": "One practical styling tip",
    "color_harmony": "Description of color coordination",
    "vibe": "Primary aesthetic",
    "items": [
      {"id": "id1", "role": "top"},
      {"id": "id2", "role": "bottom"},
      {"id": "id3", "role": "shoes"}
    ]
  }
]

Return ONLY the JSON array, no markdown or commentary.`;

    const response = await callOpenRouter(
      MODELS.GEMINI_FLASH_LITE,
      [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt }
      ],
      { temperature: 0.7, max_tokens: 3000 }
    );

    const responseText = response.choices[0]?.message?.content || "";
    let outfits: unknown[] = extractJSON(responseText);

    // Validate item IDs exist
    const validItemIds = new Set(wardrobeItems.map((item: WardrobeItem) => item.id));
    outfits = outfits.filter((outfit: unknown) => {
      const o = outfit as { wardrobe_item_ids?: string[] };
      return o.wardrobe_item_ids?.every((id: string) => validItemIds.has(id));
    });

    if (outfits.length === 0) {
      throw new Error("No valid outfits generated");
    }

    // Sort by score
    outfits.sort((a: unknown, b: unknown) => {
      const scoreA = (a as { score?: number }).score || 0;
      const scoreB = (b as { score?: number }).score || 0;
      return scoreB - scoreA;
    });

    console.log(`Generated ${outfits.length} outfits`);

    // Store in daily queue
    const { error: queueError } = await supabase
      .from("daily_outfit_queue")
      .upsert({
        user_id: userId,
        outfits: outfits,
        occasion: occasion,
        weather: weather,
        style_vector_snapshot: styleData?.style_vector || null,
        generated_at: new Date().toISOString(),
        expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
      }, {
        onConflict: "user_id"
      });

    if (queueError) {
      console.error("Queue storage error:", queueError);
    }

    return new Response(
      JSON.stringify({ success: true, outfits }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Generation error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

function categorizeItems(items: WardrobeItem[]): Record<string, WardrobeItem[]> {
  const categories: Record<string, WardrobeItem[]> = {};
  for (const item of items) {
    const cat = item.category || "other";
    if (!categories[cat]) categories[cat] = [];
    categories[cat].push(item);
  }
  return categories;
}

function getCurrentSeason(): string {
  const month = new Date().getMonth();
  if (month >= 2 && month <= 4) return "spring";
  if (month >= 5 && month <= 7) return "summer";
  if (month >= 8 && month <= 10) return "fall";
  return "winter";
}

function getTimeOfDay(): string {
  const hour = new Date().getHours();
  if (hour >= 5 && hour < 12) return "morning";
  if (hour >= 12 && hour < 17) return "afternoon";
  if (hour >= 17 && hour < 21) return "evening";
  return "night";
}
