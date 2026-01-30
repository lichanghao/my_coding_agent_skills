# Workflow to prepare materials

## 1. Choose pre-defined format
- When a user asks for preparing materials, first confirm if the requested type has been included in pre-defined format.
- If it is not defined, use "RedNote posts with three paragraphs" by default.

## 2. Confirm the recommended music
- Check dialog history to see if the user has confirmed the scope of recommended music. 
- If the scope is clear, go to the next step. 
- If the scope is not clear, use other core capabilities in [skill.md](../SKILL.md) to explicitly ask user to confirm the scope of music (list).

## 3. Search and download materials
- For each music in the list, search on Youtube to find the [link] of complete video and download them in `./download`. 
- Here is the example command to download the video (replace [link] with the Youtube link for each music): `yt-dlp -f -f "bestvideo[ext=mp4][vcodec^=avc]+bestaudio[ext=m4a]/best[ext=mp4]/best" --merge-output-format mp4 [link] --cookies-from-browser  chrome`
- if `yt-dlp` is not installed, remind the user and find ways to fix.
- Use [the clip script](../scripts/climax_clip.sh) to automatically find the best point to clip: "climax_clip.sh [input.mp4] [output_clip.mp4]".
- Use [the cover script](../scripts/save_first_frame.sh) to clip the first frame of the video as the cover of this post.
- Use [the post cover generator script](../scripts/generate_cover.py) to generate high-resolution: `python generate_cover.py [input image] --prompt [prompt]` **Use the following prompt: "This is an album art with relative low resolution. I need to expand it to a 3:4 high resolution image for my post for music recommendation on social media. You need to maximally keep the art genre of this album art and imaginatively expand it without significant change of visual effect. Then add theme word to the center position, the first line should be 《[music name]》, and the second line should be [artist name]. Use yellow, italic fonts with sense of design. Line spacing should be medium to clearly see the separation."**
- Use [the overlay script](../scripts/overlay_cover.sh) to overlay the clipped video onto the generated high-resolution cover image: `overlay_cover.sh [clipped_video.mp4] [generated_cover.jpg] [final_output.mp4]`.

## 4. Generate caption for posts
Use the functionality "Persona-Driven Content Generation" in [skill.md](../SKILL.md) to write a caption with the user-specified format in Step 1: "Choose pre-defined format". 
**Important: Explicitly ask user for the final output language.**
After confirm the output language, write down the caption with the user-specified language.
### List of pre-defined format
- **RedNote posts with three paragraphs**: Three paragraphs, the first paragraph should introduce the album and the historical background, and the singer's characteristics. If the production team has any other well-known artists, mention them a bit. The second paragraph should introduce the content, specific style, and the "message trying to convey" by the music. The third paragraph should do an analysis on music arrangement, including rhythm, chord, instruments, etc. 
