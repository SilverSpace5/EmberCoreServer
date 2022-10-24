extends Node

var network
var port = 31400

func _ready():
	StartServer()

func StartServer():
	network = WebSocketServer.new()
	network.listen(port, [], true)
	get_tree().set_network_peer(network)
	#print("Server started")

	network.connect("peer_connected", self, "_Peer_Connected")
	network.connect("peer_disconnected", self, "_Peer_Disconnected")

func _Peer_Connected(player_id):
	#print("User " + str(player_id), " Connected")
	pass

func _Peer_Disconnected(player_id):
	#print("User " + str(player_id), " Disconnected")
	pass

remote func fetchData(id):
	#print("Fetching Data: " + id)
	rpc_id(get_tree().get_rpc_sender_id(), "returnData", yield(Database.getData(id), "completed"))

remote func setData(id, data):
	#print("Settings Data: " + id + " to " + str(data))
	Database.setData(id, data)

remote func deleteData(id):
	Database.deleteData(id)

remote func listData():
	#print("Listing Data")
	rpc_id(get_tree().get_rpc_sender_id(), "returnList", yield(Database.getDatabase(), "completed"))
