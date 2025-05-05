import '../tests/question_model.dart';

List<QuestionModel> questions = [
  QuestionModel(
    "Dans quel pays sommes-nous ?",
    {
      "France": false,   
      "Usa": false,
      "Tunisie": true,
      "Japon": false,
    },
  ),
  QuestionModel("Dans quelle continent sommes-nous ?", {
    "Amerique Nord": false,
    "Asie": false,
    "Europe": false,
    "Afrique": true,
  }),
  QuestionModel("Dans quelle région ?", {
    "Tunis": true,
    "Gabes": false,
    "Sfax": false,
    "Sousse": false,
  }),
  QuestionModel("Dans quelle ville ?", {
    "Wed el lil": false,
    "Nabeul": false,
    "Manouba": true,
    "Hassi el Jerbi": false,
  }),
  QuestionModel("Quelle année sommes-nous ?", {
    "${DateTime.now().year}": true,
    "${DateTime.now().year - 1}": false,
    "${DateTime.now().year - 2}": false,
    "${DateTime.now().year + 1}": false,
  }),
  QuestionModel("Combien de jours y a-t-il dans une semaine ?", {
    "8": false,
    "12": false,
    "7": true,
    "11": false,
  }),
  QuestionModel(
      "Combien de mois dans une année ?", {
    "13": false,
    "14": false,
    "11": false,
    "12": true,
  }),
  QuestionModel("Combien de jours y a-t-il en février (année non bissextile) ?", {
    "24": false,
    "29": false,
    "28": true,
    "26": false,
  }),
  QuestionModel(
      "Combien y a-t-il d’heures dans une journée ?", {
    "22": false,
    "27": false,
    "24": true,
    "25": false,
  }),
  QuestionModel(
      "Quelle est le nom de cette application ?", {
    "Remember me": true,
    "tfakrni": false,
    "find me": false,
    "winik": false,
  }),
];