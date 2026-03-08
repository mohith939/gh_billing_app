import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/widgets/common_footer.dart';
import '../../data/models/user_model.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  final userBox = HiveDatabase.userBox;

  void _addUser() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final shopNameController = TextEditingController();
    final phoneController = TextEditingController();
    final upiController = TextEditingController();
    final addr1Controller = TextEditingController();
    final addr2Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password')),
              TextField(controller: shopNameController, decoration: const InputDecoration(labelText: 'Shop Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Mobile Number')),
              TextField(controller: upiController, decoration: const InputDecoration(labelText: 'UPI ID')),
              TextField(controller: addr1Controller, decoration: const InputDecoration(labelText: 'Address Line 1')),
              TextField(controller: addr2Controller, decoration: const InputDecoration(labelText: 'Address Line 2')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final user = UserModel(
                email: emailController.text.trim().toLowerCase(),
                password: passwordController.text,
                shopName: shopNameController.text,
                phoneNumber: phoneController.text,
                upiId: upiController.text,
                addressLine1: addr1Controller.text,
                addressLine2: addr2Controller.text,
                expiryDate: DateTime.now().add(const Duration(days: 30)),
              );
              userBox.put(user.email, user);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _updateExpiry(UserModel user) {
    showDatePicker(
      context: context,
      initialDate: user.expiryDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    ).then((selectedDate) {
      if (selectedDate != null) {
        final updatedUser = user.copyWith(expiryDate: selectedDate);
        userBox.put(user.email, updatedUser);
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final users = userBox.values.where((u) => !u.isSuperAdmin).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final daysLeft = user.expiryDate?.difference(DateTime.now()).inDays ?? 0;
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(user.shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${user.email}'),
                  Text('Phone: ${user.phoneNumber}'),
                  Text('Expires: ${user.expiryDate?.toString().split(' ')[0] ?? 'N/A'} ($daysLeft days left)'),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.blue),
                onPressed: () => _updateExpiry(user),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const CommonFooter(),
    );
  }
}
