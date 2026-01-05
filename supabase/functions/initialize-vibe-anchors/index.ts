import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { runClipText } from "../_shared/replicate.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Vibe definitions with rich descriptions for embedding
const VIBE_DEFINITIONS: Record<string, string> = {
  // Aesthetics
  "Dark Academia": "Tweed blazers, oxford shoes, turtlenecks, earth tones, brown leather, vintage books aesthetic, scholarly, muted colors, wool, herringbone patterns, argyle sweaters, corduroy pants",
  "Cottagecore": "Floral dresses, linen, prairie style, straw hats, soft pastels, romantic, rural, handmade aesthetic, puff sleeves, eyelet lace, gingham patterns, embroidered blouses",
  "Y2K": "Low-rise jeans, butterfly clips, velour tracksuits, metallic fabrics, baby tees, platform shoes, bedazzled, cyber, Paris Hilton aesthetic, rhinestones, mini skirts, tube tops",
  "Minimalist": "Clean lines, neutral palette, white black gray beige, quality basics, no logos, simple silhouettes, understated elegance, capsule wardrobe, timeless pieces",
  "Streetwear": "Hoodies, sneakers, graphic tees, oversized fits, hype brands, urban style, skateboard influence, bold logos, cargo pants, bucket hats, high-top sneakers",
  "Gorpcore": "Technical outerwear, hiking boots, fleece vests, functional fashion, outdoor brands, utility pockets, earth tones, Patagonia, The North Face, performance fabrics",
  "Old Money": "Quiet luxury, cashmere, navy blazers, pearl jewelry, nautical stripes, preppy, timeless, no visible logos, quality fabrics, Ralph Lauren aesthetic, loafers",
  "Grunge": "Flannel shirts, ripped jeans, combat boots, band tees, layered looks, dark colors, 90s Seattle, distressed denim, Doc Martens, oversized cardigans",
  "Bohemian": "Flowing fabrics, earthy tones, layered jewelry, fringe, embroidery, free-spirited, maxi dresses, natural materials, paisley prints, turquoise accessories",
  "Preppy": "Polo shirts, cable knit sweaters, chinos, boat shoes, collegiate style, clean-cut, pastel colors, tennis aesthetic, blazers with crests, madras patterns",
  "Punk": "Leather jackets, studs, safety pins, band patches, combat boots, tartan, DIY aesthetic, rebellious, black clothing, ripped fishnet, chains, spikes",
  "Coastal Grandmother": "Linen pants, white button-downs, wicker bags, soft neutrals, relaxed elegance, Nancy Meyers aesthetic, cashmere, straw hats, comfortable sandals",
  "Eclectic Grandpa": "Vintage menswear, oversized cardigans, quirky patterns, corduroy, interesting textures, thrifted aesthetic, mismatched prints, vintage spectacles",
  "Clean Girl": "Slicked back hair, gold hoops, neutral palette, minimal makeup aesthetic, simple tank tops, tailored pants, white cotton, delicate jewelry, effortless beauty",
  "Indie Sleaze": "Skinny jeans, American Apparel aesthetic, messy hair, deep v-necks, late 2000s party style, leather jackets, band merch, high-waisted shorts",
  "Quiet Luxury": "Stealth wealth, no logos, premium fabrics, perfect tailoring, muted tones, quality over quantity, The Row aesthetic, Loro Piana, understated elegance",
  "Mob Wife": "Leopard print, fur coats, gold jewelry, bold glamour, red lips, designer logos, maximalist, animal prints, chunky gold chains, dramatic sunglasses",
  "Coquette": "Bows, pink, lace, delicate jewelry, feminine, romantic, ballet flats, soft fabrics, ribbons, corset tops, Mary Jane shoes, pearl details",
  "Corporate": "Tailored suits, pencil skirts, blazers, professional, polished, structured bags, classic pumps, button-down shirts, power dressing",
  "Athleisure": "Leggings, sneakers, sports bras, casual athletic wear, comfortable, gym-to-street style, matching sets, performance fabrics, yoga pants",
  // Eras
  "1950s": "Full skirts, cinched waists, pearls, cat-eye glasses, elegant dresses, feminine silhouettes, Audrey Hepburn, poodle skirts, saddle shoes",
  "1960s": "Mod fashion, mini skirts, bold geometric patterns, go-go boots, shift dresses, Twiggy style, Peter Pan collars, color blocking",
  "1970s": "Bell bottoms, disco, earth tones, platform shoes, bohemian, suede, fringe, Studio 54, halter tops, wide-leg pants, psychedelic prints",
  "1980s": "Power shoulders, neon colors, excess, athletic influence, big hair, bold patterns, Dynasty style, leg warmers, shoulder pads, metallic fabrics",
  "1990s": "Minimalism, slip dresses, grunge flannel, denim everything, simple silhouettes, Kate Moss, chokers, combat boots, mom jeans",
  "2000s": "Low-rise everything, velour, logomania, trucker hats, butterfly clips, Paris Hilton era, bedazzled denim, tiny handbags, layered tanks",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    console.log("Initializing vibe anchor embeddings with Jina CLIP...");

    const results: { vibe: string; success: boolean; error?: string; embedding_type: string }[] = [];

    for (const [vibeName, description] of Object.entries(VIBE_DEFINITIONS)) {
      try {
        console.log(`Processing: ${vibeName}`);

        // Generate real embedding using Jina CLIP text encoder
        let embedding: number[];
        let embeddingType = "jina-clip";

        try {
          embedding = await runClipText(description);
          console.log(`Generated ${embedding.length}-dim embedding for ${vibeName}`);
        } catch (clipError) {
          console.error(`Jina CLIP failed for ${vibeName}, using fallback:`, clipError);
          // Fallback to pseudo-embedding if CLIP is unavailable
          embedding = generateFallbackEmbedding(description);
          embeddingType = "fallback";
        }

        const category = vibeName.match(/^\d{4}s$/) ? "era" : "aesthetic";

        // Update or insert vibe anchor
        const { error } = await supabase
          .from("vibe_anchors")
          .upsert({
            vibe_name: vibeName,
            description: description,
            category: category,
            embedding: embedding,
            updated_at: new Date().toISOString()
          }, {
            onConflict: "vibe_name"
          });

        if (error) {
          console.error(`Failed to update ${vibeName}:`, error);
          results.push({ vibe: vibeName, success: false, error: error.message, embedding_type: embeddingType });
        } else {
          console.log(`Updated: ${vibeName} (${embeddingType})`);
          results.push({ vibe: vibeName, success: true, embedding_type: embeddingType });
        }

        // Small delay to avoid rate limiting
        await new Promise((resolve) => setTimeout(resolve, 500));

      } catch (e) {
        console.error(`Error processing ${vibeName}:`, e);
        results.push({ vibe: vibeName, success: false, error: (e as Error).message, embedding_type: "none" });
      }
    }

    const successCount = results.filter(r => r.success).length;
    const jinaCount = results.filter(r => r.embedding_type === "jina-clip").length;
    const fallbackCount = results.filter(r => r.embedding_type === "fallback").length;

    console.log(`Initialized ${successCount}/${results.length} vibe anchors`);
    console.log(`Jina CLIP embeddings: ${jinaCount}, Fallback embeddings: ${fallbackCount}`);

    return new Response(
      JSON.stringify({
        success: true,
        results,
        summary: {
          total: results.length,
          successful: successCount,
          jina_clip: jinaCount,
          fallback: fallbackCount
        }
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Initialization error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// Fallback embedding for when Jina CLIP is unavailable
function generateFallbackEmbedding(text: string): number[] {
  const embedding = new Array(512).fill(0);

  // Create deterministic embedding based on text content
  for (let i = 0; i < text.length; i++) {
    const charCode = text.charCodeAt(i);
    for (let j = 0; j < 512; j++) {
      embedding[j] += Math.sin(charCode * (j + 1) * (i + 1) * 0.001) * 0.01;
    }
  }

  // Normalize
  const magnitude = Math.sqrt(embedding.reduce((sum, val) => sum + val * val, 0));
  if (magnitude > 0) {
    for (let i = 0; i < 512; i++) {
      embedding[i] /= magnitude;
    }
  }

  return embedding;
}
