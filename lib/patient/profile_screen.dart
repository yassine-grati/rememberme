import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/widgets/gradient_background.dart';

// Constants for styling
const kWhiteTextStyle = TextStyle(color: Colors.white, fontSize: 18);
const kLabelStyle = TextStyle(color: Colors.white70);
const kBorderRadius = 12.0;
const kWhite54Border = BorderSide(color: Colors.white54);
const kWhiteBorder = BorderSide(color: Colors.white);
const kRedAccentBorder = BorderSide(color: Colors.redAccent);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Utilisateur';
  String _age = 'N/A';
  int _educationYears = 0;
  String _email = 'N/A';
  String _gender = 'N/A';
  double _physicalActivity = 0.0;
  double _sleepQuality = 0.0;
  bool _familyHistoryAlzheimers = false;
  bool _diabetes = false;
  String _userType = 'patient';
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _educationController = TextEditingController();
  final _emailController = TextEditingController();
  final _physicalActivityController = TextEditingController();
  final _sleepQualityController = TextEditingController();
  String _selectedGender = 'Homme';
  bool _selectedFamilyHistoryAlzheimers = false;
  bool _selectedDiabetes = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _name = 'Utilisateur non connecté');
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Délai d\'attente dépassé pour la récupération des données');
      });

      if (!userDoc.exists || userDoc.data() == null) {
        if (mounted) setState(() => _name = 'Données non disponibles');
        _email = user.email ?? 'N/A';
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _userType = userData['userType'] ?? 'patient';
          if (_userType != 'patient') {
            _name = 'Cet écran est réservé aux patients';
            return;
          }
          _name = userData['name'] ?? 'Utilisateur';
          _age = userData['age']?.toString() ?? 'N/A';
          _educationYears = userData['education_years'] ?? 0;
          _email = userData['email'] ?? user.email ?? 'N/A';
          _gender = userData['gender'] ?? 'N/A'; // Gender is stored as string
          _physicalActivity = (userData['physical_activity_hours_per_week'] ?? 0.0).toDouble();
          _sleepQuality = (userData['sleep_quality_hours_per_night'] ?? 0.0).toDouble();

          // Convert family_history_alzheimers_code to boolean
          int familyHistoryCode = userData['family_history_alzheimers_code'] ?? 0;
          _familyHistoryAlzheimers = familyHistoryCode == 1;

          // Convert diabetes_code to boolean
          int diabetesCode = userData['diabetes_code'] ?? 0;
          _diabetes = diabetesCode == 1;

          _nameController.text = _name;
          _ageController.text = _age;
          _educationController.text = _educationYears.toString();
          _emailController.text = _email;
          _physicalActivityController.text = _physicalActivity.toString();
          _sleepQualityController.text = _sleepQuality.toString();
          _selectedGender = _gender;
          _selectedFamilyHistoryAlzheimers = _familyHistoryAlzheimers;
          _selectedDiabetes = _diabetes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _name = 'Erreur lors du chargement';
          _email = 'N/A';
        });
        String errorMessage = 'Échec du chargement des données de profil. Veuillez réessayer.';
        if (e.toString().contains('network')) {
          errorMessage = 'Problème de connexion réseau. Veuillez vérifier votre connexion.';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = 'Vous n\'avez pas la permission d\'accéder à ces données.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Utilisateur non connecté');

        if (_emailController.text.trim() != user.email) {
          await user.updateEmail(_emailController.text.trim());
        }

        // Map family history to integer: false (Non) -> 0, true (Oui) -> 1
        int familyHistoryCode = _selectedFamilyHistoryAlzheimers ? 1 : 0;
        // Map diabetes to integer: false (Non) -> 0, true (Oui) -> 1
        int diabetesCode = _selectedDiabetes ? 1 : 0;

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()) ?? 0,
          'education_years': int.tryParse(_educationController.text.trim()) ?? 0,
          'email': _emailController.text.trim(),
          'gender': _selectedGender, // Store gender as string
          'physical_activity_hours_per_week': double.tryParse(_physicalActivityController.text.trim()) ?? 0.0,
          'sleep_quality_hours_per_night': double.tryParse(_sleepQualityController.text.trim()) ?? 0.0,
          'family_history_alzheimers_code': familyHistoryCode,
          'diabetes_code': diabetesCode,
        });

        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        if (mounted) {
          setState(() {
            _name = _nameController.text.trim();
            _age = _ageController.text.trim();
            _educationYears = int.tryParse(_educationController.text.trim()) ?? 0;
            _email = user?.email ?? _emailController.text.trim();
            _gender = _selectedGender;
            _physicalActivity = double.tryParse(_physicalActivityController.text.trim()) ?? 0.0;
            _sleepQuality = double.tryParse(_sleepQualityController.text.trim()) ?? 0.0;
            _familyHistoryAlzheimers = _selectedFamilyHistoryAlzheimers;
            _diabetes = _selectedDiabetes;
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès !', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.black,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'Cet email est déjà utilisé par un autre compte.';
            break;
          case 'requires-recent-login':
            errorMessage = 'Veuillez vous reconnecter pour mettre à jour votre email.';
            break;
          default:
            errorMessage = 'Échec de la mise à jour du profil. Veuillez réessayer.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Échec de la mise à jour du profil. Veuillez réessayer.';
          if (e.toString().contains('network')) {
            errorMessage = 'Problème de connexion réseau. Veuillez vérifier votre connexion.';
          } else if (e.toString().contains('permission-denied')) {
            errorMessage = 'Vous n\'avez pas la permission de mettre à jour ces données.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Échec de la déconnexion. Veuillez réessayer.';
        if (e.toString().contains('network')) {
          errorMessage = 'Problème de connexion réseau. Veuillez vérifier votre connexion.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _educationController.dispose();
    _emailController.dispose();
    _physicalActivityController.dispose();
    _sleepQualityController.dispose();
    super.dispose();
  }

  // Reusable InputDecoration for form fields
  InputDecoration _buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      labelStyle: kLabelStyle,
      enabledBorder: OutlineInputBorder(
        borderSide: kWhite54Border,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: kWhiteBorder,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: kRedAccentBorder,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: kRedAccentBorder,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
    );
  }

  // Common validator for non-empty fields
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) return 'Veuillez entrer votre $fieldName';
    return null;
  }

  // Validator for numeric fields
  String? _validateNumber(String? value, String fieldName, {bool isDouble = false, double? maxValue}) {
    final error = _validateRequired(value, fieldName);
    if (error != null) return error;
    final number = isDouble ? double.tryParse(value!) : int.tryParse(value!);
    if (number == null) return 'Veuillez entrer un nombre valide';
    if (maxValue != null && number > maxValue) return '$fieldName ne peut pas dépasser $maxValue';
    return null;
  }

  // Widget for displaying profile details
  Widget _buildProfileDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nom d\'utilisateur : $_name', style: kWhiteTextStyle),
        const SizedBox(height: 20),
        Text('Âge : $_age', style: kWhiteTextStyle),
        const SizedBox(height: 20),
        Text('Genre : $_gender', style: kWhiteTextStyle),
        const SizedBox(height: 20),
        Text('Années d\'études : $_educationYears', style: kWhiteTextStyle),
        const SizedBox(height: 20),
        Text('Activité physique : $_physicalActivity heures/semaine', style: kWhiteTextStyle),
        const SizedBox(height: 20),
        Text('Qualité du sommeil : $_sleepQuality heures/nuit', style: kWhiteTextStyle),
        const SizedBox(height: 20),
        Text('Antécédents familiaux d\'Alzheimer : ${_familyHistoryAlzheimers ? 'Oui' : 'Non'}', style: kWhiteTextStyle),
        const SizedBox(height: 20),
        Text('Diabète : ${_diabetes ? 'Oui' : 'Non'}', style: kWhiteTextStyle),
        const SizedBox(height: 20),
        Text('Email : $_email', style: kWhiteTextStyle),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildButton('Modifier', () => setState(() => _isEditing = true)),
            _buildButton('Se déconnecter', _signOut),
          ],
        ),
      ],
    );
  }

  // Widget for editing profile details
  Widget _buildProfileEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            style: kWhiteTextStyle,
            decoration: _buildInputDecoration('Nom d\'utilisateur'),
            validator: (value) => _validateRequired(value, 'nom d\'utilisateur'),
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _ageController,
            style: kWhiteTextStyle,
            decoration: _buildInputDecoration('Âge'),
            keyboardType: TextInputType.number,
            validator: (value) => _validateNumber(value, 'âge'),
          ),
          const SizedBox(height: 16.0),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: _buildInputDecoration('Genre'),
            dropdownColor: Colors.black87,
            style: kWhiteTextStyle,
            items: ['Homme', 'Femme', 'Autre']
                .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                .toList(),
            onChanged: (value) => setState(() => _selectedGender = value!),
            validator: (value) => _validateRequired(value, 'genre'),
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _educationController,
            style: kWhiteTextStyle,
            decoration: _buildInputDecoration('Années d\'études'),
            keyboardType: TextInputType.number,
            validator: (value) => _validateNumber(value, 'années d\'études'),
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _physicalActivityController,
            style: kWhiteTextStyle,
            decoration: _buildInputDecoration('Activité physique (heures/semaine)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) => _validateNumber(value, 'activité physique', isDouble: true, maxValue: 168.0),
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _sleepQualityController,
            style: kWhiteTextStyle,
            decoration: _buildInputDecoration('Qualité du sommeil (heures/nuit)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) => _validateNumber(value, 'qualité du sommeil', isDouble: true, maxValue: 24.0),
          ),
          const SizedBox(height: 16.0),
          SwitchListTile(
            title: const Text('Antécédents familiaux d\'Alzheimer', style: kWhiteTextStyle),
            value: _selectedFamilyHistoryAlzheimers,
            onChanged: (value) => setState(() => _selectedFamilyHistoryAlzheimers = value),
            activeColor: Colors.white,
            inactiveTrackColor: Colors.white54,
          ),
          const SizedBox(height: 16.0),
          SwitchListTile(
            title: const Text('Diabète', style: kWhiteTextStyle),
            value: _selectedDiabetes,
            onChanged: (value) => setState(() => _selectedDiabetes = value),
            activeColor: Colors.white,
            inactiveTrackColor: Colors.white54,
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _emailController,
            style: kWhiteTextStyle,
            decoration: _buildInputDecoration('Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Veuillez entrer un email valide';
              return null;
            },
          ),
          const SizedBox(height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildButton('Enregistrer', _updateUserDetails),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _nameController.text = _name;
                    _ageController.text = _age;
                    _educationController.text = _educationYears.toString();
                    _emailController.text = _email;
                    _physicalActivityController.text = _physicalActivity.toString();
                    _sleepQualityController.text = _sleepQuality.toString();
                    _selectedGender = _gender;
                    _selectedFamilyHistoryAlzheimers = _familyHistoryAlzheimers;
                    _selectedDiabetes = _diabetes;
                  });
                },
                child: const Text('Annuler', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Reusable button widget
  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1976D2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ) ?? const TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24.0),
                    if (_userType == 'patient') ...[
                      _isEditing ? _buildProfileEditForm() : _buildProfileDisplay(),
                    ] else
                      Text(_name, style: kWhiteTextStyle),
                  ],
                ),
              ),
            ),
    );
  }
}