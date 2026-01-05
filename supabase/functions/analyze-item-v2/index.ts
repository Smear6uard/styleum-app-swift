import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callOpenRouter, MODELS, extractJSON } from "../_shared/openrouter.ts";
import { runFlorence2, runClipImage } from "../_shared/replicate.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface AnalyzeRequest {
  item_id: string;
  image_url: string;
  user_id?: string;
}

interface FashionAnalysis {
  item_name: string;
  category: "top" | "bottom" | "shoes" | "outerwear" | "accessory" | "dress" | "other";
  subcategory: string;
  primary_color: string;
  secondary_colors: string[];
  color_hex: string;
  material: string;
  fit: "slim" | "regular" | "relaxed" | "oversized";
  formality: number;
  seasonality: string[];
  occasions: string[];
  style_bucket: string;
  era: string;
  era_confidence: number;
  vibe_scores: Record<string, number>;
  dense_caption: string;
  notable_details: string;
  style_description: string;
  is_unorthodox: boolean;
  unorthodox_reason?: string;
  ocr_text?: string;
  brand?: string;
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

    const { item_id, image_url, user_id }: AnalyzeRequest = await req.json();

    if (!item_id || !image_url) {
      throw new Error("Missing item_id or image_url");
    }

    console.log(`Analyzing item: ${item_id}`);

    // ============================================================
    // Step 1: Dense Captioning via Florence-2
    // ============================================================
    console.log("Step 1: Running Florence-2 for dense captioning...");
    let denseCaption: string;
    try {
      denseCaption = await runFlorence2(image_url, "more_detailed_caption");
      console.log("Dense caption generated via Florence-2");
    } catch (florenceError) {
      console.error("Florence-2 caption failed, falling back to Gemini:", florenceError);
      // Fallback to Gemini if Florence-2 fails
      const florencePrompt = `Analyze this clothing item in extreme detail. Describe the garment type, colors, patterns, materials, construction details, fit, any visible text or brand markings, condition, and unique features. Be extremely specific.`;
      const florenceResponse = await callOpenRouter(
        MODELS.GEMINI_FLASH_LITE,
        [{ role: "user", content: [
          { type: "text", text: florencePrompt },
          { type: "image_url", image_url: { url: image_url } }
        ]}],
        { temperature: 0.1, max_tokens: 1024 }
      );
      denseCaption = florenceResponse.choices[0]?.message?.content || "";
    }

    // ============================================================
    // Step 2: OCR via Florence-2
    // ============================================================
    console.log("Step 2: Running Florence-2 for OCR...");
    let ocrText: string;
    try {
      ocrText = await runFlorence2(image_url, "ocr");
      if (!ocrText || ocrText.trim() === "") {
        ocrText = "NO_TEXT_VISIBLE";
      }
      console.log("OCR complete via Florence-2");
    } catch (ocrError) {
      console.error("Florence-2 OCR failed, falling back to Gemini:", ocrError);
      // Fallback to Gemini if Florence-2 fails
      const ocrPrompt = `Extract ALL visible text from this clothing item image: brand names, size labels, care instructions, "Made in" labels, date codes. Return only the extracted text, one item per line. If no text is visible, return "NO_TEXT_VISIBLE".`;
      const ocrResponse = await callOpenRouter(
        MODELS.GEMINI_FLASH_LITE,
        [{ role: "user", content: [
          { type: "text", text: ocrPrompt },
          { type: "image_url", image_url: { url: image_url } }
        ]}],
        { temperature: 0, max_tokens: 256 }
      );
      ocrText = ocrResponse.choices[0]?.message?.content || "NO_TEXT_VISIBLE";
    }

    // ============================================================
    // Step 3: Fetch user's previous corrections for few-shot learning
    // ============================================================
    let userContext = "";
    if (user_id) {
      const { data: corrections } = await supabase
        .from("tag_corrections")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", { ascending: false })
        .limit(5);

      if (corrections && corrections.length > 0) {
        userContext = `\n\nUSER PREFERENCE CONTEXT (learn from their previous corrections):
${corrections.map((c: { field_name: string; original_value: string; corrected_value: string }) =>
  `- Changed "${c.field_name}" from "${c.original_value}" to "${c.corrected_value}"`
).join("\n")}`;
      }
    }

    // ============================================================
    // Step 4: Semantic Reasoning via Gemini (TEXT ONLY - no image)
    // ============================================================
    console.log("Step 4: Running Gemini for semantic reasoning...");
    const reasoningPrompt = `You are an expert fashion archivist, vintage authenticator, and subculture historian. Analyze this clothing item using forensic fashion analysis.

DENSE CAPTION FROM VISION MODEL (Florence-2):
${denseCaption}

OCR TEXT DETECTED:
${ocrText}
${userContext}

Perform the following analysis:

## STEP 1: FORENSIC ANALYSIS
- Analyze the silhouette (boxy=90s, fitted=2000s, hourglass=50s, oversized=current)
- Analyze fabric and hardware for age markers
- Analyze any visible labels/text for dating clues

## STEP 2: ERA DETECTION
Estimate the decade of origin (1950s-Contemporary)

## STEP 3: VIBE/AESTHETIC CLASSIFICATION
Map visual features to aesthetics (give confidence 0-1 for each that applies):
Dark Academia, Cottagecore, Y2K, Minimalist, Streetwear, Gorpcore, Old Money, Grunge, Bohemian, Preppy, Punk, Coastal Grandmother, Eclectic Grandpa, Clean Girl, Indie Sleaze, Quiet Luxury, Mob Wife, Coquette, Corporate, Athleisure

## STEP 4: UNORTHODOX CHECK
Is this item "unorthodox" (avant-garde, deconstructed, DIY, defies categories)?

Return your analysis as a JSON object with this EXACT schema:
{
  "item_name": "descriptive name like 'Vintage Faded Levi's 501 Jeans'",
  "category": "one of: top, bottom, shoes, outerwear, accessory, dress, other",
  "subcategory": "specific type like 'high-waisted straight-leg jeans'",
  "primary_color": "main color",
  "secondary_colors": ["other colors"],
  "color_hex": "#hexcode of primary",
  "material": "fabric type",
  "fit": "one of: slim, regular, relaxed, oversized",
  "formality": 1-5,
  "seasonality": ["spring", "summer", "fall", "winter"],
  "occasions": ["casual", "work", "date", "formal", "workout", "lounge"],
  "style_bucket": "primary style category",
  "era": "decade like '1990s' or 'Contemporary'",
  "era_confidence": 0.0-1.0,
  "vibe_scores": {"aesthetic_name": confidence_score},
  "dense_caption": "the detailed description",
  "notable_details": "unique features",
  "style_description": "how to style this item",
  "is_unorthodox": true/false,
  "unorthodox_reason": "why if applicable",
  "brand": "detected brand or null"
}

Return ONLY valid JSON, no markdown or extra text.`;

    // Note: TEXT ONLY - no image sent to Gemini (Florence-2 already processed it)
    const reasoningResponse = await callOpenRouter(
      MODELS.GEMINI_FLASH_LITE,
      [{ role: "user", content: reasoningPrompt }],
      { temperature: 0.2, max_tokens: 2048 }
    );

    const reasoningText = reasoningResponse.choices[0]?.message?.content || "";
    const analysis: FashionAnalysis = extractJSON(reasoningText);

    // Override with actual Florence-2 outputs
    analysis.dense_caption = denseCaption;
    analysis.ocr_text = ocrText !== "NO_TEXT_VISIBLE" ? ocrText : undefined;

    console.log("Semantic reasoning complete");

    // ============================================================
    // Step 5: Generate Embedding via Jina CLIP
    // ============================================================
    console.log("Step 5: Generating embedding via Jina CLIP...");
    let embedding: number[];
    try {
      embedding = await runClipImage(image_url);
      console.log(`Embedding generated: ${embedding.length} dimensions`);
    } catch (clipError) {
      console.error("Jina CLIP failed, using fallback pseudo-embedding:", clipError);
      // Fallback to pseudo-embedding if CLIP fails
      embedding = generateFallbackEmbedding(JSON.stringify(analysis));
    }

    // ============================================================
    // Step 6: Match to Vibe Anchors
    // ============================================================
    console.log("Step 6: Matching to vibe anchors...");
    try {
      const { data: nearestVibes } = await supabase.rpc("match_vibe_anchors", {
        query_embedding: embedding,
        match_threshold: 0.5, // Lower threshold for real embeddings
        match_count: 5
      });

      if (nearestVibes && nearestVibes.length > 0) {
        for (const vibe of nearestVibes) {
          // Boost vibe scores based on embedding similarity
          const currentScore = analysis.vibe_scores[vibe.vibe_name] || 0;
          analysis.vibe_scores[vibe.vibe_name] = Math.max(currentScore, vibe.similarity);
        }
        console.log(`Matched ${nearestVibes.length} vibe anchors`);
      }
    } catch (rpcError) {
      console.log("Vibe anchor matching skipped:", rpcError);
    }

    // ============================================================
    // Step 7: Update Database with ALL AI fields
    // ============================================================
    console.log("Step 7: Updating database...");
    const updateData: Record<string, unknown> = {
      // Basic fields
      item_name: analysis.item_name,
      subcategory: analysis.subcategory,
      primary_color: analysis.primary_color,
      secondary_colors: analysis.secondary_colors,
      color_hex: analysis.color_hex,
      material: analysis.material,
      fit: analysis.fit,
      formality: analysis.formality,
      style_bucket: analysis.style_bucket,
      brand: analysis.brand,
      tags: generateTags(analysis),

      // AI analysis fields
      dense_caption: denseCaption,
      ocr_text: ocrText !== "NO_TEXT_VISIBLE" ? ocrText : null,
      era: analysis.era,
      era_confidence: analysis.era_confidence,
      vibe_scores: analysis.vibe_scores,
      is_unorthodox: analysis.is_unorthodox,
      notable_details: analysis.notable_details,
      style_description: analysis.style_description,

      // Embedding
      embedding: embedding,

      // Metadata
      analyzed_at: new Date().toISOString(),
    };

    const { error: updateError } = await supabase
      .from("wardrobe_items")
      .update(updateData)
      .eq("id", item_id);

    if (updateError) {
      console.error("Database update error:", updateError);
      throw updateError;
    }

    console.log(`Analysis complete for item: ${item_id}`);

    return new Response(
      JSON.stringify({
        success: true,
        analysis,
        embedding_dimensions: embedding.length,
        pipeline: {
          captioning: "florence-2",
          ocr: "florence-2",
          reasoning: "gemini",
          embedding: "jina-clip"
        }
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Analysis error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// Fallback embedding for when Jina CLIP is unavailable
function generateFallbackEmbedding(text: string): number[] {
  const embedding = new Array(512).fill(0);
  for (let i = 0; i < text.length; i++) {
    const charCode = text.charCodeAt(i);
    for (let j = 0; j < 512; j++) {
      embedding[j] += Math.sin(charCode * (j + 1) * (i + 1) * 0.001) * 0.01;
    }
  }
  const magnitude = Math.sqrt(embedding.reduce((sum, val) => sum + val * val, 0));
  if (magnitude > 0) {
    for (let i = 0; i < 512; i++) {
      embedding[i] /= magnitude;
    }
  }
  return embedding;
}

function generateTags(analysis: FashionAnalysis): string[] {
  const tags: Set<string> = new Set();

  tags.add(analysis.category);
  tags.add(analysis.subcategory);
  tags.add(analysis.primary_color.toLowerCase());
  tags.add(analysis.material.toLowerCase());
  tags.add(analysis.fit);
  tags.add(analysis.style_bucket.toLowerCase());

  if (analysis.era !== "Contemporary") {
    tags.add(analysis.era.toLowerCase());
    tags.add("vintage");
  }

  for (const vibe of Object.keys(analysis.vibe_scores)) {
    if (analysis.vibe_scores[vibe] > 0.5) {
      tags.add(vibe.toLowerCase().replace(/\s+/g, "-"));
    }
  }

  for (const color of analysis.secondary_colors) {
    tags.add(color.toLowerCase());
  }

  for (const occasion of analysis.occasions) {
    tags.add(occasion.toLowerCase());
  }

  for (const season of analysis.seasonality) {
    tags.add(season.toLowerCase());
  }

  if (analysis.brand) {
    tags.add(analysis.brand.toLowerCase());
  }

  const formalityLabels = ["very-casual", "casual", "smart-casual", "business-casual", "formal"];
  if (analysis.formality >= 1 && analysis.formality <= 5) {
    tags.add(formalityLabels[analysis.formality - 1]);
  }

  return Array.from(tags);
}
