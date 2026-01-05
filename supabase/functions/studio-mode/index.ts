import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { removeBackground } from "../_shared/replicate.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface StudioModeRequest {
  item_id: string;
  image_url: string;
}

interface StudioModeResponse {
  success: boolean;
  photo_url_clean?: string;
  fallback?: boolean;
  error?: string;
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

    const { item_id, image_url }: StudioModeRequest = await req.json();

    if (!item_id || !image_url) {
      throw new Error("Missing item_id or image_url");
    }

    console.log(`[Studio Mode] Processing item: ${item_id}`);

    // ============================================================
    // Step 1: Remove background via BRIA RMBG 2.0
    // ============================================================
    console.log("[Studio Mode] Calling BRIA RMBG 2.0...");
    const cleanImageUrl = await removeBackground(image_url);

    if (!cleanImageUrl) {
      console.log("[Studio Mode] Background removal failed, returning fallback");
      const response: StudioModeResponse = {
        success: false,
        fallback: true,
        photo_url_clean: image_url, // Return original as fallback
        error: "Background removal failed, using original image"
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    console.log("[Studio Mode] Background removed successfully");

    // ============================================================
    // Step 2: Download the processed image
    // ============================================================
    console.log("[Studio Mode] Downloading processed image...");
    const imageResponse = await fetch(cleanImageUrl);
    if (!imageResponse.ok) {
      throw new Error(`Failed to download processed image: ${imageResponse.status}`);
    }
    const imageData = await imageResponse.arrayBuffer();
    console.log(`[Studio Mode] Downloaded ${imageData.byteLength} bytes`);

    // ============================================================
    // Step 3: Upload to Supabase Storage
    // ============================================================
    const fileName = `clean/${item_id}_clean.png`;
    console.log(`[Studio Mode] Uploading to storage: ${fileName}`);

    const { error: uploadError } = await supabase.storage
      .from("wardrobe")
      .upload(fileName, imageData, {
        contentType: "image/png",
        upsert: true // Overwrite if exists
      });

    if (uploadError) {
      console.error("[Studio Mode] Upload error:", uploadError);
      throw new Error(`Storage upload failed: ${uploadError.message}`);
    }

    // Get public URL
    const { data: publicUrlData } = supabase.storage
      .from("wardrobe")
      .getPublicUrl(fileName);

    const publicUrl = publicUrlData.publicUrl;
    console.log(`[Studio Mode] Public URL: ${publicUrl}`);

    // ============================================================
    // Step 4: Update database
    // ============================================================
    console.log("[Studio Mode] Updating database...");
    const { error: updateError } = await supabase
      .from("wardrobe_items")
      .update({
        photo_url_clean: publicUrl,
        studio_mode_at: new Date().toISOString()
      })
      .eq("id", item_id);

    if (updateError) {
      console.error("[Studio Mode] Database update error:", updateError);
      throw new Error(`Database update failed: ${updateError.message}`);
    }

    console.log(`[Studio Mode] Complete for item: ${item_id}`);

    // ============================================================
    // Step 5: Return success
    // ============================================================
    const response: StudioModeResponse = {
      success: true,
      photo_url_clean: publicUrl
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    });

  } catch (error) {
    console.error("[Studio Mode] Error:", error);

    const response: StudioModeResponse = {
      success: false,
      error: (error as Error).message
    };

    return new Response(JSON.stringify(response), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    });
  }
});
