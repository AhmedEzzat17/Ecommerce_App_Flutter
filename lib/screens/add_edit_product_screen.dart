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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price *'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: _categories
                  .map(
                    (cat) => DropdownMenuItem<String>(
                      value: cat['id'].toString(),
                      child: Text(cat['name']),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(labelText: 'Budget Range *'),
              items: ['Low', 'Medium', 'High']
                  .map(
                    (p) => DropdownMenuItem<String>(value: p, child: Text(p)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedPriority = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (Optional)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date (Optional)',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.image),
              label: Text('Select Images (${_pickedImages.length})'),
            ),
            const SizedBox(height: 32),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(
                      'Save Product',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
