class_name VisitorDefinition
extends SpeakerDefinition
## Посетитель: кто он, что рассказывает, что отвечает на вопросы и как реагирует на решение.
## В репликах смысловые фразы размечены как `[текст|id]`; остальной текст не записывается.

## Какое дело заводит принятое заявление. Пусто — заявление ни к чему не ведёт.
@export var case_definition: CaseDefinition
## Портрет сидящего посетителя при ровном дневном свете, с прозрачным фоном.
@export var portrait: Texture2D
## Размер относительно обычного посетителя: маленькая старушка меньше, крупный мужик больше.
@export var portrait_scale: float = 1.0
## С чем человек приходит: первая реплика.
@export_multiline var monologue: String
@export var knowledge: Array[KnowledgeEntry] = []
## Ответы в характере, когда человеку нечего сказать по вопросу. Идут по кругу.
@export var fallback_replies: PackedStringArray = PackedStringArray()
@export_multiline var accept_reply: String
@export_multiline var refuse_reply: String
## Удастся ли уговорить не писать заявление.
@export var can_be_talked_out: bool = false
@export_multiline var talk_out_success_reply: String
## Ответ, если уговорить не удалось: человек остаётся и ждёт решения.
@export_multiline var talk_out_fail_reply: String


## Строка таблицы знаний для вопроса о факте или `null`.
func find_answer(fact: FactDefinition, question: QuestionTemplate) -> KnowledgeEntry:
	for entry: KnowledgeEntry in knowledge:
		if entry.matches(fact, question):
			return entry
	return null


## Все реплики посетителя, где может встретиться разметка.
func get_all_texts() -> Array[String]:
	var texts: Array[String] = [
		monologue, accept_reply, refuse_reply, talk_out_success_reply, talk_out_fail_reply,
	]
	texts.append_array(Array(fallback_replies))
	for entry: KnowledgeEntry in knowledge:
		texts.append(entry.answer)
	return texts
