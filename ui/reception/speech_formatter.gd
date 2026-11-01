@abstract
class_name SpeechFormatter
extends RefCounted
## Превращает реплику в BBCode для `RichTextLabel`. Смысловая фраза — ссылка с идентификатором
## факта; записанная в блокнот фраза подчёркнута и выделена цветом. Незаписанные ничем
## не выделены, обычный текст не кликается.


static func to_bbcode(line: SpokenLine, notebook: Notebook, captured_color: Color) -> String:
	var bbcode: String = ""
	for chunk: SpeechChunk in line.chunks:
		var text: String = escape(chunk.text)
		if not chunk.is_capturable():
			bbcode += text
			continue
		if notebook.has(chunk.fact.id):
			text = "[u][color=#%s]%s[/color][/u]" % [captured_color.to_html(false), text]
		bbcode += "[url=%s]%s[/url]" % [chunk.fact.id, text]
	return bbcode


## Экранировать текст, чтобы он не читался как BBCode.
static func escape(text: String) -> String:
	return text.replace("[", "[lb]")
