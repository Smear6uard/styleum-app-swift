// Shared Replicate client for AI model inference
// Models: Florence-2, Jina CLIP v2, BRIA RMBG

const REPLICATE_API = "https://api.replicate.com/v1/predictions";

// Model versions (pinned for stability)
const MODELS = {
  FLORENCE_2: "lucataco/florence-2-large:da53547e17d45b9cfb48174b2f18af8b83ca020fa76db62136bf9c6616762595",
  JINA_CLIP: "zsxkib/jina-clip-v2:5050c3108bab23981802011a3c76ee327cc0dbfdd31a2f4ef1ee8ef0d3f0b448",
  BRIA_RMBG: "bria/remove-background:4ed060b3587b7c3912353dd7d59000c883a6e1c5c9181ed7415c2624c2e8e392",
} as const;

interface ReplicatePrediction {
  id: string;
  status: "starting" | "processing" | "succeeded" | "failed" | "canceled";
  output: unknown;
  error?: string;
}

/**
 * Get Replicate API token from environment
 */
function getApiToken(): string {
  // Try both possible env var names
  const token = Deno.env.get("REPLICATE_API_TOKEN") || Deno.env.get("REPLICATE_API_KEY");
  if (!token) {
    throw new Error("Missing REPLICATE_API_TOKEN or REPLICATE_API_KEY environment variable");
  }
  return token;
}

/**
 * Create a prediction and poll until complete
 */
async function runPrediction(
  model: string,
  input: Record<string, unknown>
): Promise<unknown> {
  const token = getApiToken();

  // Create prediction
  const createResponse = await fetch(REPLICATE_API, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
      "Prefer": "wait", // Use sync mode for faster response
    },
    body: JSON.stringify({
      version: model.split(":")[1],
      input,
    }),
  });

  if (!createResponse.ok) {
    const error = await createResponse.text();
    console.error(`Replicate create error:`, error);
    throw new Error(`Replicate API error: ${createResponse.status}`);
  }

  let prediction: ReplicatePrediction = await createResponse.json();

  // Poll if not complete (in case sync mode didn't work)
  let attempts = 0;
  const maxAttempts = 60; // 60 seconds max

  while (prediction.status !== "succeeded" && prediction.status !== "failed") {
    if (attempts >= maxAttempts) {
      throw new Error("Replicate prediction timeout");
    }

    await new Promise((resolve) => setTimeout(resolve, 1000));

    const pollResponse = await fetch(
      `${REPLICATE_API}/${prediction.id}`,
      {
        headers: { "Authorization": `Bearer ${token}` },
      }
    );

    if (!pollResponse.ok) {
      throw new Error(`Replicate poll error: ${pollResponse.status}`);
    }

    prediction = await pollResponse.json();
    attempts++;
  }

  if (prediction.status === "failed") {
    throw new Error(`Replicate prediction failed: ${prediction.error}`);
  }

  return prediction.output;
}

// ============================================================
// Florence-2: Vision-Language Model for Captioning and OCR
// ============================================================

type Florence2Task =
  | "Caption"
  | "Detailed Caption"
  | "More Detailed Caption"
  | "OCR"
  | "OCR with Region";

/**
 * Run Florence-2 for dense captioning or OCR
 *
 * @param imageUrl - URL of the image to analyze
 * @param task - The vision task to perform
 * @returns The text output (caption or OCR result)
 */
export async function runFlorence2(
  imageUrl: string,
  task: "caption" | "detailed_caption" | "more_detailed_caption" | "ocr"
): Promise<string> {
  const taskMap: Record<string, Florence2Task> = {
    caption: "Caption",
    detailed_caption: "Detailed Caption",
    more_detailed_caption: "More Detailed Caption",
    ocr: "OCR",
  };

  console.log(`[Florence-2] Running ${task} on image...`);

  const output = await runPrediction(MODELS.FLORENCE_2, {
    image: imageUrl,
    task_input: taskMap[task],
  });

  // Florence-2 returns output as a string or object depending on task
  if (typeof output === "string") {
    return output;
  }

  // Handle object output (some tasks return structured data)
  if (output && typeof output === "object") {
    // For caption tasks, output is usually in a specific key
    const result = output as Record<string, unknown>;
    if (result[taskMap[task]]) {
      return String(result[taskMap[task]]);
    }
    // Fallback: stringify the output
    return JSON.stringify(output);
  }

  return String(output || "");
}

// ============================================================
// Jina CLIP v2: Multimodal Embeddings (Image + Text)
// ============================================================

/**
 * Generate 512-dimensional embedding from an image
 *
 * @param imageUrl - URL of the image to embed
 * @returns 512-dimensional embedding array
 */
export async function runClipImage(imageUrl: string): Promise<number[]> {
  console.log(`[Jina CLIP] Generating image embedding...`);

  const output = await runPrediction(MODELS.JINA_CLIP, {
    image: imageUrl,
    embedding_dim: 512,
    output_format: "array",
  });

  if (!Array.isArray(output)) {
    throw new Error("Jina CLIP did not return an array");
  }

  // Handle nested array output [[...]] -> [...]
  let embedding: number[];
  if (Array.isArray(output[0])) {
    embedding = output[0] as number[];
  } else {
    embedding = output as number[];
  }

  // Normalize the embedding to unit vector
  const magnitude = Math.sqrt(embedding.reduce((sum, val) => sum + val * val, 0));
  if (magnitude > 0) {
    for (let i = 0; i < embedding.length; i++) {
      embedding[i] /= magnitude;
    }
  }

  console.log(`[Jina CLIP] Generated ${embedding.length}-dim embedding`);
  return embedding;
}

/**
 * Generate 512-dimensional embedding from text description
 *
 * @param text - Text to embed (for vibe anchors)
 * @returns 512-dimensional embedding array
 */
export async function runClipText(text: string): Promise<number[]> {
  console.log(`[Jina CLIP] Generating text embedding...`);

  const output = await runPrediction(MODELS.JINA_CLIP, {
    text: text,
    embedding_dim: 512,
    output_format: "array",
  });

  if (!Array.isArray(output)) {
    throw new Error("Jina CLIP did not return an array");
  }

  // Handle nested array output [[...]] -> [...]
  let embedding: number[];
  if (Array.isArray(output[0])) {
    embedding = output[0] as number[];
  } else {
    embedding = output as number[];
  }
  const magnitude = Math.sqrt(embedding.reduce((sum, val) => sum + val * val, 0));
  if (magnitude > 0) {
    for (let i = 0; i < embedding.length; i++) {
      embedding[i] /= magnitude;
    }
  }

  console.log(`[Jina CLIP] Generated ${embedding.length}-dim text embedding`);
  return embedding;
}

// ============================================================
// BRIA RMBG 2.0: Background Removal
// ============================================================

/**
 * Remove background from an image
 *
 * @param imageUrl - URL of the image to process
 * @returns URL of the processed image with background removed, or null on failure
 */
export async function removeBackground(imageUrl: string): Promise<string | null> {
  console.log(`[BRIA RMBG] Removing background...`);

  try {
    const output = await runPrediction(MODELS.BRIA_RMBG, {
      image_url: imageUrl,
      preserve_alpha: true,
      content_moderation: false,
    });

    if (typeof output === "string") {
      console.log(`[BRIA RMBG] Background removed successfully`);
      return output;
    }

    console.error(`[BRIA RMBG] Unexpected output type:`, typeof output);
    return null;
  } catch (error) {
    console.error(`[BRIA RMBG] Failed:`, error);
    return null;
  }
}

// ============================================================
// Exports for backward compatibility with plan naming
// ============================================================

// Aliases matching the plan's function names
export const runFashionSigLIP = runClipImage;
export const runFashionSigLIPText = runClipText;
