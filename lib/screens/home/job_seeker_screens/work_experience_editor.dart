import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/job _seeker_models/work_experience_model.dart';

class WorkExperienceEditor extends StatefulWidget {
  final Function(WorkExperience) onExperienceAdded;
  final List<WorkExperience> existingExperience;
  final WorkExperience? initialExperience; // Added here

  const WorkExperienceEditor({
    Key? key,
    required this.onExperienceAdded,
    required this.existingExperience,
    this.initialExperience, // Added here
  }) : super(key: key);

  @override
  _WorkExperienceEditorState createState() => _WorkExperienceEditorState();
}

class _WorkExperienceEditorState extends State<WorkExperienceEditor> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _positionController;
  late TextEditingController _descriptionController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;

  @override
  void initState() {
    super.initState();
    final experience = widget.initialExperience;
    _companyController = TextEditingController(text: experience?.company ?? '');
    _positionController = TextEditingController(text: experience?.positionTitle ?? '');
    _descriptionController = TextEditingController(text: experience?.description ?? '');
    _startDate = experience?.startDate;
    _endDate = experience?.endDate;
    _isCurrent = experience?.isCurrent ?? false;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || (!_isCurrent && _endDate == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select dates')),
        );
        return;
      }

      final experience = WorkExperience(
        company: _companyController.text,
        positionTitle: _positionController.text,
        description: _descriptionController.text,
        startDate: _startDate!,
        endDate: _isCurrent ? null : _endDate,
        isCurrent: _isCurrent,
      );

      widget.onExperienceAdded(experience);

      // Clear form if not editing
      if (widget.initialExperience == null) {
        _companyController.clear();
        _positionController.clear();
        _descriptionController.clear();
        setState(() {
          _startDate = null;
          _endDate = null;
          _isCurrent = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialExperience != null
                    ? 'Edit Work Experience'
                    : 'Add Work Experience',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(_startDate == null
                          ? 'Start Date'
                          : DateFormat.yMMMd().format(_startDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(_isCurrent
                          ? 'Currently Working'
                          : _endDate == null
                          ? 'End Date'
                          : DateFormat.yMMMd().format(_endDate!)),
                      trailing: _isCurrent
                          ? Checkbox(
                        value: true,
                        onChanged: (val) => setState(() => _isCurrent = val!),
                      )
                          : IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context, false),
                      ),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Currently Working Here'),
                value: _isCurrent,
                onChanged: (value) => setState(() => _isCurrent = value),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.initialExperience != null ? 'Update' : 'Add Work Experience'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
