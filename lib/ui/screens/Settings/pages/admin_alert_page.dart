import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminAlertPage extends StatefulWidget {
  const AdminAlertPage({super.key});

  @override
  State<AdminAlertPage> createState() => _AdminAlertPageState();
}

class _AdminAlertPageState extends State<AdminAlertPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Broadcast Controllers
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _imageController = TextEditingController();
  
  // Power Controls
  bool _maintenanceMode = false;
  bool _enableForceUpdate = false;
  final _minVersionController = TextEditingController();
  final _updateUrlController = TextEditingController();
  final _homeBannerController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadCurrentConfig();
    _loadUserStats();
    _loadActivePoll();
  }

  // Polls
  final _pollQuestionController = TextEditingController();
  final _pollOption1Controller = TextEditingController();
  final _pollOption2Controller = TextEditingController();
  final _pollOption3Controller = TextEditingController();
  final _pollOption4Controller = TextEditingController();
  Map<String, dynamic>? _activePoll;
  bool _isPollActive = false;

  void _loadActivePoll() {
     _firestore.collection('alerts').doc('poll').snapshots().listen((snapshot) {
       if (snapshot.exists && snapshot.data() != null) {
         final data = snapshot.data()!;
         if (mounted) {
            setState(() {
              _activePoll = data;
              _isPollActive = data['active'] ?? false;
            });
         }
       }
     });
  }

  Future<void> _createPoll() async {
    if (_pollQuestionController.text.isEmpty || _pollOption1Controller.text.isEmpty || _pollOption2Controller.text.isEmpty) {
      Get.snackbar("Error", "Question and at least 2 Options are required");
      return;
    }

    _runAction(() async {
      List<String> options = [
        _pollOption1Controller.text.trim(),
        _pollOption2Controller.text.trim(),
      ];
      if (_pollOption3Controller.text.isNotEmpty) options.add(_pollOption3Controller.text.trim());
      if (_pollOption4Controller.text.isNotEmpty) options.add(_pollOption4Controller.text.trim());

      await _firestore.collection('alerts').doc('poll').set({
        'id': DateTime.now().millisecondsSinceEpoch,
        'question': _pollQuestionController.text.trim(),
        'options': options,
        'votes': {}, // Map of OptionIndex -> Count
        'active': true,
        'type': 'poll',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      Get.snackbar("Success", "🗳️ Poll is LIVE now!");
      _pollQuestionController.clear();
      _pollOption1Controller.clear();
      _pollOption2Controller.clear();
      _pollOption3Controller.clear();
      _pollOption4Controller.clear();
    });
  }

  Future<void> _endPoll() async {
    _runAction(() async {
      await _firestore.collection('alerts').doc('poll').update({'active': false});
      Get.snackbar("Ended", "Poll has been stopped.");
    });
  }


  // User Stats
  int _totalUsers = 0;
  String _searchQuery = "";
  Map<String, dynamic>? _searchedUser;
  bool _isSearching = false;

  void _loadUserStats() async {
    try {
      final snapshot = await _firestore.collection('users').count().get();
      setState(() {
        _totalUsers = snapshot.count ?? 0;
      });
    } catch (e) {
      debugPrint("Stats load error: $e");
    }
  }

  Future<void> _searchUser() async {
    if (_searchQuery.isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchedUser = null;
    });

    try {
      // Search by Email
      final query = await _firestore.collection('users')
          .where('email', isEqualTo: _searchQuery.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() => _searchedUser = query.docs.first.data());
      } else {
        // Try searching by ID if email failed
        final doc = await _firestore.collection('users').doc(_searchQuery.trim()).get();
        if (doc.exists) {
          setState(() => _searchedUser = doc.data());
        } else {
           Get.snackbar("Not Found", "User not found with this Email or ID");
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Search failed: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _toggleUserStatus(String uid, String field, bool currentValue) async {
    _runAction(() async {
      await _firestore.collection('users').doc(uid).update({
        field: !currentValue,
      });
      // Refresh search result locally
      if (_searchedUser != null) {
        setState(() {
          _searchedUser![field] = !currentValue;
        });
      }
      Get.snackbar("Updated", "User $field changed to ${!currentValue}");
    });
  }

  void _loadCurrentConfig() async {
    try {
      // FIX PATH: system/config (Consistent with Rules and CloudService)
      final doc = await _firestore.collection('system').doc('config').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _maintenanceMode = data['maintenanceMode'] ?? false;
          _enableForceUpdate = data['enableForceUpdate'] ?? false;
          _minVersionController.text = data['minVersion'] ?? '1.0.0';
          _updateUrlController.text = data['updateUrl'] ?? '';
          _homeBannerController.text = data['homeBannerUrl'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Config load error: $e");
    }
  }

  // ==================== ACTIONS ====================

  Future<void> _sendBroadcast() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      Get.snackbar("Error", "Title and Message are required");
      return;
    }
    _runAction(() async {
      await _firestore.collection('alerts').doc('global').set({
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'imageUrl': _imageController.text.trim().isNotEmpty ? _imageController.text.trim() : null,
        'active': true,
        'type': 'alert',
        'timestamp': FieldValue.serverTimestamp(),
      });
      Get.snackbar("Success", "📢 Broadcast Sent!");
      _titleController.clear();
      _messageController.clear();
      _imageController.clear();
    });
  }

  Future<void> _updateSystemConfig() async {
    _runAction(() async {
      // FIX PATH: system/config
      await _firestore.collection('system').doc('config').set({
        'maintenanceMode': _maintenanceMode,
        'enableForceUpdate': _enableForceUpdate,
        'minVersion': _minVersionController.text.trim(),
        'updateUrl': _updateUrlController.text.trim(),
        'homeBannerUrl': _homeBannerController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      Get.snackbar("Saved", "⚙️ System Config Updated!");
    });
  }

  Future<void> _triggerFunEvent(String type) async {
    _runAction(() async {
      await _firestore.collection('events').doc('live').set({
        'type': type, // 'confetti' or 'toast'
        'message': "Admin says Hello!",
        'triggeredAt': DateTime.now().millisecondsSinceEpoch,
      });
      Get.snackbar("Fun", "🎉 $type Triggered!");
    });
  }

  void _runAction(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
    } catch (e) {
      Get.snackbar("Error", "Action Failed: $e", backgroundColor: Colors.red.withValues(alpha: 0.5));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shivaay Command Center"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.campaign), text: "Broadcast"),
            Tab(icon: Icon(Icons.settings_suggest), text: "Controls"),
            Tab(icon: Icon(Icons.celebration), text: "Fun Zone"),
            Tab(icon: Icon(Icons.people_alt), text: "Users & Stats"),
            Tab(icon: Icon(Icons.verified), text: "Verification"),
            Tab(icon: Icon(Icons.poll), text: "Live Polls"),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : TabBarView(
          controller: _tabController,
          children: [
            _buildBroadcastTab(),
            _buildControlsTab(),
            _buildFunZoneTab(),
            _buildUsersTab(),
            _buildVerificationTab(),
            _buildPollsTab(),
          ],
        ),
    );
  }

  // TAB 5: POLLS
  Widget _buildPollsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ACTIVE POLL DISPLAY
          if (_isPollActive && _activePoll != null) ...[
            Card(
              color: Colors.green.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("🔴 LIVE POLL ACTIVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(_activePoll!['question'] ?? "Question", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Divider(),
                    // Options List
                    ...(_activePoll!['options'] as List<dynamic>).asMap().entries.map((entry) {
                      final idx = entry.key;
                      final txt = entry.value;
                      // Mock vote count - in real app, read from 'votes' map
                      final votes = (_activePoll!['votes'] as Map?)?['$idx'] ?? 0;
                      return ListTile(
                        leading: CircleAvatar(child: Text("${idx+1}")),
                        title: Text(txt),
                        trailing: Text("$votes Votes", style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _endPoll,
                      icon: const Icon(Icons.stop_circle),
                      label: const Text("END POLL"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(thickness: 2),
            const SizedBox(height: 30),
          ],

          // CREATE NEW POLL
          const Text("Create New Poll", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(controller: _pollQuestionController, decoration: const InputDecoration(labelText: "Question", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: TextField(controller: _pollOption1Controller, decoration: const InputDecoration(labelText: "Option 1", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _pollOption2Controller, decoration: const InputDecoration(labelText: "Option 2", border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 15),
           Row(
            children: [
              Expanded(child: TextField(controller: _pollOption3Controller, decoration: const InputDecoration(labelText: "Option 3 (Optional)", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _pollOption4Controller, decoration: const InputDecoration(labelText: "Option 4 (Optional)", border: OutlineInputBorder()))),
            ],
          ),
           const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isPollActive ? null : _createPoll, // Disable create if one is active
              icon: const Icon(Icons.how_to_vote),
              label: Text(_isPollActive ? "POLL ALREADY ACTIVE" : "LAUNCH POLL"),
              style: ElevatedButton.styleFrom(backgroundColor: _isPollActive ? Colors.grey : Colors.deepPurple, foregroundColor: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  // TAB: VERIFICATION (BLUE TICK)
  Widget _buildVerificationTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').where('isVerified', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final verifiedUsers = snapshot.data!.docs;
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.blue.withValues(alpha: 0.1),
                child: ListTile(
                  leading: const Icon(Icons.verified, color: Colors.blue, size: 30),
                  title: const Text("Total Verified Users", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text("${verifiedUsers.length}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: verifiedUsers.isEmpty 
                ? const Center(child: Text("No users verified yet."))
                : ListView.builder(
                    itemCount: verifiedUsers.length,
                    itemBuilder: (context, index) {
                      final data = verifiedUsers[index].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: data['photoUrl'] != null ? NetworkImage(data['photoUrl']) : null,
                          child: data['photoUrl'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(data['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(data['email'] ?? ""),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => _toggleUserStatus(data['uid'], 'isVerified', true),
                          tooltip: "Remove Blue Tick",
                        ),
                      );
                    },
                  ),
            ),
          ],
        );
      },
    );
  }

  // TAB 4: USERS & STATS
  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 1. STATS CARD
          Card(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text("TOTAL USERS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text("$_totalUsers", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.blueAccent)),
                    ],
                  ),
                  const Column(
                    children: [
                      Text("ACTIVE NOW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text("--", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.green)), // Requires Realtime DB
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          // 2. USER LOOKUP
          const Text("User Lookup", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: "Enter Email or User UID",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchUser,
              )
            ),
            onChanged: (val) => _searchQuery = val,
            onSubmitted: (_) => _searchUser(),
          ),
          
          if (_isSearching) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),

          if (_searchedUser != null) ...[
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(_searchedUser!['photoUrl'] ?? ''),
                        child: _searchedUser!['photoUrl'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(_searchedUser!['name'] ?? 'Unknown Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_searchedUser!['email'] ?? 'No Email'),
                      trailing: _searchedUser!['isVerified'] == true ? const Icon(Icons.verified, color: Colors.blue) : null,
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text("Last Login", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(_searchedUser!['lastLogin'] != null 
                              ? _formatTimestamp(_searchedUser!['lastLogin']) 
                              : "Never", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        // Actions
                        IconButton(
                          icon: Icon(_searchedUser!['isBanned'] == true ? Icons.block : Icons.check_circle_outline),
                          color: _searchedUser!['isBanned'] == true ? Colors.red : Colors.green,
                          tooltip: _searchedUser!['isBanned'] == true ? "Unban User" : "Ban User",
                          onPressed: () => _toggleUserStatus(_searchedUser!['uid'], 'isBanned', _searchedUser!['isBanned'] ?? false),
                        ),
                        IconButton(
                          icon: Icon(_searchedUser!['isVerified'] == true ? Icons.verified : Icons.verified_outlined),
                          color: Colors.blue,
                          tooltip: "Toggle Verified",
                          onPressed: () => _toggleUserStatus(_searchedUser!['uid'], 'isVerified', _searchedUser!['isVerified'] ?? false),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return "--";
    final dt = ts.toDate();
    return "${dt.day}/${dt.month} ${dt.hour}:${dt.minute}";
  }

  // TAB 1: BROADCAST
  Widget _buildBroadcastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.campaign_outlined, size: 60, color: Colors.blueAccent),
          const SizedBox(height: 10),
          const Text("Send Global Alert", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Alert Title", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _messageController, maxLines: 3, decoration: const InputDecoration(labelText: "Message", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _imageController, decoration: const InputDecoration(labelText: "Image URL (Optional)", border: OutlineInputBorder())),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _sendBroadcast,
              icon: const Icon(Icons.send),
              label: const Text("SEND BROADCAST"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  // TAB 2: CONTROLS
  Widget _buildControlsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.security, size: 60, color: Colors.redAccent),
          const SizedBox(height: 10),
          const Text("System Controls", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // Maintenance Switch
          SwitchListTile(
            title: const Text("Maintenance Mode"),
            subtitle: const Text("Disable app for all users (Emergency)"),
            value: _maintenanceMode,
            activeThumbColor: Colors.red,
            onChanged: (val) => setState(() => _maintenanceMode = val),
            secondary: const Icon(Icons.build_circle),
          ),
          
          // Force Update Switch
          SwitchListTile(
            title: const Text("Enable Force Update Check"),
            subtitle: const Text("Enforce min version on users"),
            value: _enableForceUpdate,
            activeThumbColor: Colors.orange,
            onChanged: (val) => setState(() => _enableForceUpdate = val),
            secondary: const Icon(Icons.system_update_alt),
          ),

          const Divider(),
          
          // Min Version
          TextField(
            controller: _minVersionController,
            decoration: const InputDecoration(
              labelText: "Min Supported Version (e.g. 1.0.2)",
              prefixIcon: Icon(Icons.restore),
              border: OutlineInputBorder()
            ),
          ),
          const SizedBox(height: 15),
          
          // Update URL
          TextField(
            controller: _updateUrlController,
            decoration: const InputDecoration(
              labelText: "Update Download URL",
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder()
            ),
          ),
          const SizedBox(height: 15),

          // Home Banner
          TextField(
            controller: _homeBannerController,
            decoration: const InputDecoration(
              labelText: "Home Screen Banner URL",
              prefixIcon: Icon(Icons.image),
              border: OutlineInputBorder()
            ),
          ),
          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _updateSystemConfig,
              icon: const Icon(Icons.save_as),
              label: const Text("UPDATE SYSTEM CONFIG"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  // TAB 3: FUN ZONE
  Widget _buildFunZoneTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sentiment_very_satisfied, size: 80, color: Colors.purpleAccent),
          const SizedBox(height: 20),
          const Text("Fun Interactions", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildFunButton("Confetti Blast", Icons.celebration, Colors.purple, () => _triggerFunEvent('confetti')),
              _buildFunButton("Global Toast", Icons.chat_bubble, Colors.amber, () => _triggerFunEvent('toast')),
              _buildFunButton("Dark Mode", Icons.dark_mode, Colors.black87, () => _triggerFunEvent('theme_dark')),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFunButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 150,
      height: 120,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        ),
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
