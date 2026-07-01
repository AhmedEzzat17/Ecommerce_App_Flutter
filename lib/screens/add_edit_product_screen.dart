import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const AddEditProductScreen({Key? key, this.product}) : super(key: key);

  @override
  _AddEditProductScreenState createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedCategory;
  String _selectedPriority = 'Low';
  List<dynamic> _categories = [];
  bool _isSaving = false;
  List<XFile> _pickedImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) { //لو مش فاضيه
      _titleController.text = widget.product!['title'] ?? '';
      _priceController.text = widget.product!['price']?.toString() ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      _noteController.text = widget.product!['note'] ?? '';
      _dateController.text = widget.product!['date'] ?? '';
      _selectedPriority = widget.product!['Budget_Range'] ?? widget.product!['priority'] ?? 'Low';
    }
    _fetchCategories(); //دى داله
  }

  void _fetchCategories() async {
    final cats = await ApiService.getCategories();
    setState(() {
      _categories = cats;
      _selectedCategory =
          (widget.product != null && widget.product!['category'] != null)
          ? widget.product!['category']['id']?.toString()
          : (cats.isNotEmpty ? cats[0]['id']?.toString() : null);
    });
  }

  void _pickImages() async {
    final images = await ImagePicker().pickMultiImage();
    setState(() => _pickedImages = images);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(
        () => _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}",
      );
    }
  }

  void _saveProduct() async {
    if (_titleController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isSaving = true);
    List<String> imagePaths = _pickedImages.map((e) => e.path).toList();

    bool success = widget.product != null
        ? await ApiService.updateProduct(
            widget.product!['id'],
            _titleController.text,
            _priceController.text,
            _selectedCategory!,
            _selectedPriority,
            _descriptionController.text,
            _noteController.text,
            _dateController.text,
            imagePaths,
          )
        : await ApiService.addProduct(
            _titleController.text,
            _priceController.text,
            _selectedCategory!,
            _selectedPriority,
            _descriptionController.text,
            _noteController.text,
            _dateController.text,
            imagePaths,
          );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save product')));
    }
  }

  InputDecoration _inputDecoration(String label, [IconData? icon]) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
      suffixIcon: icon != null ? Icon(icon, color: Colors.blueGrey) : null,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: _inputDecoration('Title *'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: _inputDecoration('Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: _inputDecoration('Price *', Icons.attach_money),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: _inputDecoration('Category *'),
              items: _categories
                  .map((cat) => DropdownMenuItem<String>(value: cat['id'].toString(), child: Text(cat['name'])))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: _inputDecoration('Budget Range *'),
              items: ['Low', 'Medium', 'High']
                  .map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedPriority = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: _inputDecoration('Note (Optional)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              decoration: _inputDecoration('Date (Optional)', Icons.calendar_today),
              readOnly: true,
              onTap: _selectDate,
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      _pickedImages.isEmpty ? 'Tap to select product images' : '${_pickedImages.length} images selected',
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
