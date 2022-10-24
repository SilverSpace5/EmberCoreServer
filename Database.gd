extends Node

var ip = "wss://databasetest.silverspace505.repl.co"
var peer = WebSocketClient.new()
var connected = false
var returnData = {}
var gotData = false
var fetchedData = {}
var list = []
var lastUsed = 30
var fetchedList = false

func sendMsg(data, wait=false):
	peer.get_peer(1).put_packet(JSON.print(data).to_utf8())
	if wait:
		returnData = {}
		gotData = false
		yield(get_tree().create_timer(0), "timeout")
		while not gotData:
			yield(get_tree().create_timer(0.1), "timeout")
		return returnData

func setData(id, data):
	lastUsed = 30
	sendMsg({"databaseset": data, "databaseid": id})
	if not id in list:
		fetchedList = true
		list.append(id)
	if id in list:
		fetchedData[id] = data

func getData(id):
	yield(get_tree().create_timer(0), "timeout")
	if not fetchedData.has(id):
		lastUsed = 30
		var data = yield(sendMsg({"databaseget": id}, true), "completed")
		fetchedData[id] = data
	return fetchedData[id]

func getDatabase():
	yield(get_tree().create_timer(0), "timeout")
	if list == [] and not fetchedList:
		lastUsed = 30
		list = yield(sendMsg({"databaselist": "idk"}, true), "completed")
	fetchedList = true
	return list

func deleteData(id):
	sendMsg({"databasedelete": id})
	if list != []:
		if id in list:
			list.remove(id)
			fetchedData.erase(id)

func connectToDatabase():
	print("Connecting to Database")
	peer.disconnect_from_host()
	peer = WebSocketClient.new()
	peer.connect("connection_established", self, "_connected")
	peer.connect("connection_error", self, "_closed")
	peer.connect("connection_closed", self, "_closed")
	peer.connect("data_received", self, "_on_data")
	peer.connect_to_url(ip)

func _ready():
	while not connected:
		connectToDatabase()
		yield(get_tree().create_timer(2), "timeout")

func _process(delta):
	peer.poll()
	
	lastUsed -= delta
	if lastUsed <= 0:
		lastUsed = 2
		if fetchedList:
			for key in list:
				if not fetchedData.has(key):
					fetchedData[key] = yield(getData(key), "completed")
		else:
			list = yield(getDatabase(), "completed")

func _connected(proto):
	print("Connected to Database")
	connected = true
	peer.get_peer(1).put_packet(JSON.print({"join": "0"}).to_utf8())

func _closed(was_clean = false):
	print("Disconnected")
	connected = false
	while not connected:
		connectToDatabase()
		yield(get_tree().create_timer(2), "timeout")

func _on_data():
	var data = JSON.parse(peer.get_peer(1).get_packet().get_string_from_utf8()).result
	
	if data.has("databaseget"):
		gotData = true
		returnData = data["databaseget"]
	if data.has("databaselist"):
		gotData = true
		returnData = data["databaselist"]
	
