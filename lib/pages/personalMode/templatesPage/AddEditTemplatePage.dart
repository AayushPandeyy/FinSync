import 'package:finance_tracker/models/TransactionTemplate.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/TemplateFirestoreService.dart';
import 'package:finance_tracker/utilities/BannerService.dart';
import 'package:finance_tracker/utilities/Categories.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Create or edit a [TransactionTemplate]. Pass [existingTemplate] to edit.
class AddEditTemplatePage extends StatefulWidget {
  final TransactionTemplate? existingTemplate;

  const AddEditTemplatePage({super.key, this.existingTemplate});

  @override
  State<AddEditTemplatePage> createState() => _AddEditTemplatePageState();
}

class _AddEditTemplatePageState extends State<AddEditTemplatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'EXPENSE';
  String? _selectedCategory;
  bool _isLoadingDialogVisible = false;

  final TemplateFirestoreService _service = TemplateFirestoreService();

  bool get _isEditing => widget.existingTemplate != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingTemplate;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _type = existing.type;
      _selectedCategory = existing.category;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _guardOfflineEntry());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _guardOfflineEntry() async {
    await ConnectivityService.ensureConnected(
      context,
      actionDescription: _isEditing ? 'edit a template' : 'add a template',
      popCurrentRouteOnFailure: true,
    );
  }

  void _setType(String type) {
    final categories = Categories().getCategories(type);
    setState(() {
      _type = type;
      if (_selectedCategory != null &&
          !categories.any((c) => c.name == _selectedCategory)) {
        _selectedCategory = null;
      }
    });
  }

  void _showLoadingDialog() {
    DialogBox().showLoadingDialog(context);
    _isLoadingDialogVisible = true;
  }

  void _hideLoadingDialog() {
    if (_isLoadingDialogVisible && mounted) {
      Navigator.of(context).pop();
      _isLoadingDialogVisible = false;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final canProceed = await ConnectivityService.ensureConnected(
      context,
      actionDescription: _isEditing ? 'edit a template' : 'add a template',
    );
    if (!canProceed) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCategory == null) {
      _showSnack('Please select a category.');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final existing = widget.existingTemplate;

    final template = TransactionTemplate(
      id: existing?.id ?? const Uuid().v1(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      type: _type,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    _showLoadingDialog();

    try {
      if (_isEditing) {
        await _service.updateTemplate(uid, template);
      } else {
        await _service.addTemplate(uid, template);
      }

      _hideLoadingDialog();
      if (!mounted) return;

      BannerService().showInterstitialAd();
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      _hideLoadingDialog();
      _showSnack(e.message ?? 'Failed to save template.');
    } catch (e) {
      _hideLoadingDialog();
      _showSnack('Failed to save template. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = Categories().getCategories(_type);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: StandardAppBar(
        title: _isEditing ? 'Edit Template' : 'Add Template',
        subtitle: 'Preset details for quick logging',
        useCustomDesign: true,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Template Type',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ChoiceChip(
                        label: const Text("Income"),
                        selected: _type == "INCOME",
                        onSelected: (_) => _setType("INCOME"),
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                            color: _type == "INCOME"
                                ? Colors.white
                                : Colors.black),
                      ),
                      ChoiceChip(
                        label: const Text("Expense"),
                        selected: _type == "EXPENSE",
                        onSelected: (_) => _setType("EXPENSE"),
                        selectedColor: Colors.red,
                        labelStyle: TextStyle(
                            color: _type == "EXPENSE"
                                ? Colors.white
                                : Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Title",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: "e.g., Lunch",
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Description",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Optional notes",
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Category",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: categories
                                  .any((c) => c.name == _selectedCategory)
                              ? _selectedCategory
                              : null,
                          hint: const Text("Select a category"),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.black, size: 28),
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                          },
                          items: categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.name,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Icon(category.icon,
                                        color: Colors.blueGrey),
                                    const SizedBox(width: 10),
                                    Text(category.name,
                                        style: const TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _type == "EXPENSE"
                            ? Colors.red
                            : Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _save,
                      child: Text(
                        _isEditing ? "Save Changes" : "Save Template",
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
