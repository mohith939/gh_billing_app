import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/widgets/common_footer.dart';
import '../../data/models/user_model.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super. Belle});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  final userBox = HiveDatabase.userBox;

  void _showUserForm({UserModel? user}) {
    final isEditing = user != null;
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController(text: user?.password ?? '');
    final shopNameController = TextEditingController(text: user?.shopName ?? '');
    final phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    final upiController = TextEditingController(text: user?.upiId ?? '');
    final addr1Controller = TextEditingController(text: user?.addressLine1 ?? '');
    final addr2Controller = TextEditingController(text: user?.addressLine2 ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController, 
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: !isEditing, // Email usually stays unique and constant
              ),
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
              final email = emailController.text.trim().toLowerCase();
              if (email.isEmpty) return;

              final newUser = UserModel(
                email: email,
                password: passwordController.text,
                shopName: shopNameController.text,
                phoneNumber: phoneController.text,
                upiId: upiController.text,
                addressLine1: addr1Controller.text,
                addressLine2: addr2Controller.text,
                footerText: user?.footerText ?? 'Thank you, Visit again!!!',
                qrCodePath: user?.qrCodePath,
                expiryDate: user?.expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                isSuperAdmin: user?.isSuperAdmin ?? false,
              );
              
              userBox.put(email, newUser);
              setState(() {});
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isEditing ? 'User updated' : 'User added'), backgroundColor: Colors.green),
              );
            },
            child: Text(isEditing ? 'Update' : 'Add'),
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

  void _deleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.shopName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              userBox.delete(user.email);
              setState(() {});
              Navigator.pop(context);
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
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
      body: users.isEmpty 
        ? const Center(child: Text('No customers added yet.'))
        : ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final daysLeft = user.expiryDate?.difference(DateTime.now()).inDays ?? 0;
              final bool isExpired = daysLeft < 0;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(user.shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.email_outlined, user.email),
                          _buildInfoRow(Icons.phone_outlined, user.phoneNumber),
                          _buildInfoRow(
                            Icons.timer_outlined, 
                            'Expires: ${user.expiryDate?.toString().split(' ')[0] ?? 'N/A'}',
                            color: isExpired ? Colors.red : (daysLeft <= 5 ? Colors.orange : Colors.green)
                          ),
                          if (isExpired)
                            const Text('SUBSCRIPTION ENDED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                          onPressed: () => _showUserForm(user: user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_month_outlined, color: Colors.orange),
                          onPressed: () => _updateExpiry(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteUser(user),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserForm(),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const CommonFooter(),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: color ?? Colors.grey[800])),
        ],
      ),
    );
  }
}
