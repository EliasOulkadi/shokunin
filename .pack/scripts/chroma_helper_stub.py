import importlib.util
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
spec = importlib.util.spec_from_file_location("chroma_helper", os.path.join(os.path.dirname(__file__), "chroma-helper.py"))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

search = mod.search
recall = mod.recall
save = mod.save
consolidate = mod.consolidate
session_list = mod.session_list
session_continue = mod.session_continue
session_save = mod.session_save
