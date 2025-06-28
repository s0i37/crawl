#!/usr/bin/python3
import json
from sys import argv

files_crawled = argv[1]
files_all = argv[2]
report = argv[3]

files = {}
for line in open(files_all).readlines():
	try:
		path = " ".join(line.split(' ')[0:-9])
		size = " ".join(line.split(' ')[-8:-6])
		date = " ".join(line.split(' ')[-5:])
		files[path] = {"size": int(size[0])*1024, "date": date, "crawled": False}
	except Exception as e:
		#print(str(e))
		pass

for line in open(files_crawled).readlines():
	path = line[1:-2]
	try:
		files[path]["crawled"] = True
	except Exception as e:
		#print(str(e))
		pass

stats = {"crawled": 0, "no_crawled": 0, "crawled_size": 0, "no_crawled_size": 0}
for path in files:
	if files[path]["crawled"]:
		stats["crawled"] += 1
		stats["crawled_size"] += files[path]["size"]
	else:
		stats["no_crawled"] += 1
		stats["no_crawled_size"] += files[path]["size"]

for stat in stats:
	print(f"{stat}: {stats[stat]}")

folders = {}
for path in files:
	ptr = None
	for folder in path.split("/"):
		if not ptr:
			if not folder in folders:
				folders[folder] = {"files": 0, "size": 0, "children": {}, "crawled":0, "no_crawled": 0}
			ptr = folders[folder]
		else:
			ptr["files"] += 1
			ptr["size"] += files[path]["size"]
			if files[path]["crawled"]:
				ptr["crawled"] += 1
			else:
				ptr["no_crawled"] += 1
			if not folder in ptr["children"]:
				ptr["children"][folder] = {"files": 0, "size": 0, "children": {}, "crawled":0, "no_crawled": 0}
			ptr = ptr["children"][folder]

out = {"name": "root", "children": []}
def walk(folder, info, childs, out):
	cover = int(info.get("crawled",0)/(info.get("crawled",0) or 1))
	out.append({"name": folder, "size": info.get("size") or 0, "cover": int(cover*100), "color":"#{c}{c}{c}".format(c="%02x"%(cover*128)), "children": []})
	for children in childs:
		walk(children, childs[children], childs[children]["children"], out[-1]["children"])
walk("/", {}, folders, out["children"])

WWW = '''<html>
<head></head>
<body>
<div id="treemap"></div>
<script src="https://unpkg.com/treemap-chart"></script>
<script>
var data = %s
var treemap = new Treemap(document.getElementById("treemap"))
.data(data)
.color(function(n){return n.color})
.size('size')
.label(function(n){return n.name + ' [' + n.size/1024 + 'KB] (' + n.cover + '%%)'})
.tooltipContent(function(d,n){return n.size + ' (' + n.cover + '%%)'})
.padding(function(){return 10})
</script>
</body>
</html>
'''
with open(report, "w") as o:
	o.write(WWW % json.dumps(out))
