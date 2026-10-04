extends RefCounted
const LOCALES=["zh","en","ja","fr","de"]
const NAMES=["简体中文","English","日本語","Français","Deutsch"]
var locale="zh"
var catalogs:Dictionary={}
var fragments:Array=[]
func _init():
	for code in LOCALES:
		if code=="zh":continue
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://locales/"+code+".json"))
		if not data is Dictionary:continue
		catalogs[code]=data
		var translation=Translation.new();translation.locale=code
		for source in data:translation.add_message(source,data[source])
		TranslationServer.add_translation(translation)
func set_language(code):
	locale=code if code in LOCALES else "zh";TranslationServer.set_locale(locale)
	fragments=catalogs.get(locale,{}).keys()
	fragments.sort_custom(func(a,b):return a.length()>b.length())
func render(value):
	var source=str(value)
	if locale=="zh":return source
	var result=TranslationServer.translate(source)
	if result!=source:return result
	var has_cjk=false
	for index in range(source.length()):
		var cp=source.unicode_at(index)
		if cp>=0x3400 and cp<=0x9fff:has_cjk=true;break
	if not has_cjk:return source
	# Catalog names and short labels embedded in a formatted sentence remain localized.
	for fragment in fragments:
		if fragment.contains("%") or fragment.length()<2:continue
		if result.contains(fragment):result=result.replace(fragment,catalogs[locale][fragment])
	return result
