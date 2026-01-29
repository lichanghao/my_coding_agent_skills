from google import genai
from google.genai import types
import base64
import os
import argparse
import mimetypes

def generate():
  parser = argparse.ArgumentParser(description="Expand an image using NanoBanana Pro Model")
  parser.add_argument("image_path", help="Path to the input image file")
  parser.add_argument("--prompt", required=True, help="Prompt for the image expansion")
  args = parser.parse_args()

  client = genai.Client(
      vertexai=True,
      api_key=os.environ.get("GOOGLE_CLOUD_API_KEY"),
  )

  mime_type, _ = mimetypes.guess_type(args.image_path)
  if not mime_type:
      mime_type = "image/jpeg"

  with open(args.image_path, "rb") as f:
      image_bytes = f.read()

  model = "gemini-3-pro-image-preview"
  contents = [
    types.Content(
      role="user",
      parts=[
        types.Part.from_text(text=args.prompt),
        types.Part.from_bytes(data=image_bytes, mime_type=mime_type)
      ]
    )
  ]

  generate_content_config = types.GenerateContentConfig(
    temperature = 1,
    top_p = 0.95,
    max_output_tokens = 32768,
    response_modalities = ["TEXT", "IMAGE"],
    safety_settings = [types.SafetySetting(
      category="HARM_CATEGORY_HATE_SPEECH",
      threshold="OFF"
    ),types.SafetySetting(
      category="HARM_CATEGORY_DANGEROUS_CONTENT",
      threshold="OFF"
    ),types.SafetySetting(
      category="HARM_CATEGORY_SEXUALLY_EXPLICIT",
      threshold="OFF"
    ),types.SafetySetting(
      category="HARM_CATEGORY_HARASSMENT",
      threshold="OFF"
    )],
    image_config=types.ImageConfig(
      aspect_ratio="3:4",
      image_size="2K",
      output_mime_type="image/jpeg",
    ),
  )

  response = client.models.generate_content(
    model = model,
    contents = contents,
    config = generate_content_config,
  )
  
  # Save generated images
  if response.candidates and response.candidates[0].content.parts:
      for i, part in enumerate(response.candidates[0].content.parts):
          if part.inline_data:
              print(f"Received inline data with mime_type: {part.inline_data.mime_type}")
              output_file = f"generated_cover_{i}.jpg"
              with open(output_file, "wb") as f:
                  f.write(part.inline_data.data)
              print(f"Saved generated image to {output_file}")
          elif part.text:
              print("Received text response:")
              print(part.text)

if __name__ == "__main__":
  generate()
