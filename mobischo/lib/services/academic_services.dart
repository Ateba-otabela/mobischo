// ignore_for_file: import_of_legacy_library_into_null_safe, constant_identifier_names, avoid_print, unnecessary_null_comparison, non_constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';
import 'package:mobischo/models/class.dart';
import 'package:http/http.dart' as http;
import 'package:mobischo/models/convocation.dart';
import 'package:mobischo/services/mobile_api_service.dart';
import 'package:mobischo/models/sequence_evaluation.dart';
import 'package:mobischo/models/year.dart';

class AcademicServices {
  static const ROOT = 'https://mobischo.com/api/school_manager';
  static const _notesRequestTimeout = Duration(seconds: 20);
  static const GET_ALL_YEARS_ACTION = 'GET_ALL_YEARS';
  static const GET_ALL_SEQUENCES_ACTION = 'GET_ALL_SEQUENCES';
  static const GET_MAIN_YEAR_ACTION = 'GET_MAIN_YEAR';

  static const GET_ALL_CLASSES_ACTION = 'GET_ALL_CLASSES';
  static const GET_MAIN_SEQUENCE_ACTION = 'GET_MAIN_SEQUENCE';
  static const CREATE_TABLE_CONVOCATION_ACTION = 'CREATE_TABLE_CONVOCATION';
  static const INSERT_CONVOCATION_ACTION = 'INSERT_CONVOCATION';
  static const GET_TEACHER_CONVOCATIONS_ACTION = 'GET_TEACHER_CONVOCATIONS';
  static const GET_PARENT_CONVOCATIONS_ACTION = 'GET_PARENT_CONVOCATIONS';

  static Future<List<Year>> getYears() async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_ALL_YEARS_ACTION;
      final response = await http
          .post(Uri.parse(ROOT), body: map)
          .timeout(_notesRequestTimeout);
      // print("get Year Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Year> years = parseYearResponse(response.body);
          return years;
        } catch (e) {
          print("error is here");
          print(e.toString());
          return <Year>[];
        }
      } else {
        return <Year>[];
      }
    } catch (e) {
      // print(e.toString());
      return <Year>[];
    }
  }

  static Future<String> getMainYear(String codeAnnee) async {
    if (codeAnnee == null) {
      return "Toutes les annees";
    } else {
      try {
        var map = <String, dynamic>{};
        map['action'] = GET_MAIN_YEAR_ACTION;
        map['codeAnnee'] = codeAnnee;

        final response = await http.post(Uri.parse(ROOT), body: map);
        // print("get main Year Response : ${response.body}");

        if (200 == response.statusCode) {
          try {
            List<Year> years = parseYearResponse(response.body);
            Year year = years.first;
            // print(matiere.LibelleMatiere.toString());
            return year.Libelle.toString();
          } catch (e) {
            print(e);
            return "";
          }
        } else {
          return "";
        }
      } catch (e) {
        return "";
      }
    }
  }

  static Future<String> getMainSequence(String codeEvaluation) async {
    if (codeEvaluation == null) {
      return "Toutes les sequences";
    } else {
      // print(" Code evaluation : ${codeEvaluation}");
      try {
        var map = <String, dynamic>{};
        map['action'] = GET_MAIN_SEQUENCE_ACTION;
        map['codeEvaluation'] = codeEvaluation;

        final response = await http.post(Uri.parse(ROOT), body: map);
        // print("get main sequence Response : ${response.body}");

        if (200 == response.statusCode) {
          try {
            List<SequenceEvaluation> sequences =
                parseSequenceEvaluationResponse(response.body);
            SequenceEvaluation sequence = sequences.first;
            // print(matiere.LibelleMatiere.toString());
            return sequence.LibelleEvaluation.toString();
          } catch (e) {
            print(e);
            return "";
          }
        } else {
          return "";
        }
      } catch (e) {
        return "";
      }
    }
  }

  static Future<List<SequenceEvaluation>> getSequences() async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_ALL_SEQUENCES_ACTION;
      final response = await http
          .post(Uri.parse(ROOT), body: map)
          .timeout(_notesRequestTimeout);
      // print("get sequences Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<SequenceEvaluation> sequences =
              parseSequenceEvaluationResponse(response.body);
          return sequences;
        } catch (e) {
          print(e.toString());
          return <SequenceEvaluation>[];
        }
      } else {
        return <SequenceEvaluation>[];
      }
    } catch (e) {
      print(e.toString());
      return <SequenceEvaluation>[];
    }
  }

  static Future<List<SequenceEvaluation>> getSequencesForNotes(
      String codeEleve) async {
    final response = await MobileApiService.post(
      '/notes/student-sequence',
      body: <String, dynamic>{
        'action': 'GET_STUDENT_SEQUENCE_AVAILABILITY',
        'codeEleve': codeEleve,
      },
    ).timeout(_notesRequestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Unable to load assessment periods');
    }
    try {
      return parseSequenceEvaluationResponse(response.body);
    } catch (_) {
      throw const FormatException('Invalid assessment periods response');
    }
  }

  static Future<String> createConvocationTable() async {
    try {
      var map = <String, dynamic>{};
      map['action'] = CREATE_TABLE_CONVOCATION_ACTION;
      final response = await http.post(Uri.parse(ROOT), body: map);
      // print("get sequences Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          return response.body;
        } catch (e) {
          print(e.toString());
          return "Error";
        }
      } else {
        return "Error";
      }
    } catch (e) {
      print(e.toString());
      return "Error";
    }
  }

  static Future<String> insertConvocations(
      String code,
      List<String> studentCodes,
      String motif,
      String description,
      String CodeEnseignement,
      String dateConvocation,
      {String? codeClasse,
      Uint8List? documentBytes,
      String? documentName}) async {
    try {
      final map = <String, String>{};
      map['action'] = INSERT_CONVOCATION_ACTION;
      map['code'] = code;
      map['CodeEleves'] = jsonEncode(studentCodes);
      if (codeClasse != null) {
        map['CodeClasse'] = codeClasse;
      }
      map['motif'] = motif;
      map['description'] = description;
      map['CodeEnseignement'] = CodeEnseignement;
      map['dateConvocation'] = dateConvocation;

      final uri = Uri.parse(ROOT);
      print('CONVOCATION URL: $uri');
      print('CONVOCATION METHOD: POST');
      print('CONVOCATION PAYLOAD: $map');

      if ((documentBytes == null) != (documentName == null)) {
        throw ArgumentError('Both document bytes and name are required.');
      }
      final response = documentBytes == null
          ? await http.post(uri, body: map)
          : await MobileApiService.postMultipart(
              '/school_manager',
              fields: map,
              file: http.MultipartFile.fromBytes(
                'document',
                documentBytes,
                filename: documentName,
              ),
              headers: const {'Accept': 'application/json'},
            );
      final contentType = response.headers['content-type'] ?? '(missing)';
      final responsePreview = response.body.length > 1000
          ? response.body.substring(0, 1000)
          : response.body;
      print('CONVOCATION STATUS: ${response.statusCode}');
      print('CONVOCATION CONTENT-TYPE: $contentType');

      final isJson = contentType.toLowerCase().contains('application/json');
      if (isJson) {
        try {
          final decoded = jsonDecode(response.body);
          print('CONVOCATION DECODED JSON: $decoded');
        } catch (error) {
          print('CONVOCATION JSON DECODE ERROR: $error');
          print('CONVOCATION RESPONSE: $responsePreview');
        }
      } else {
        print('CONVOCATION HTML/NON-JSON RESPONSE: $responsePreview');
      }

      if (200 == response.statusCode) {
        try {
          return response.body;
        } catch (e) {
          print(e.toString());
          return "Error";
        }
      } else {
        return "Error";
      }
    } catch (e) {
      print(e.toString());
      return "Error";
    }
  }

  static Future<String> insertConvocation(
    String code,
    String studentCode,
    String motif,
    String description,
    String codeEnseignement,
    String dateConvocation,
  ) {
    return insertConvocations(
      code,
      [studentCode],
      motif,
      description,
      codeEnseignement,
      dateConvocation,
    );
  }

  static Future<List<Convocation>> getTeacherConvocation(String code,
      {String? codeClasse}) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_TEACHER_CONVOCATIONS_ACTION;
      map['code'] = code;
      if (codeClasse != null) {
        map['CodeClasse'] = codeClasse;
      }

      final response = await http.post(Uri.parse(ROOT), body: map);
      // print("get teacher convocation Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Convocation> convocations =
              parseConvocationResponse(response.body);
          return convocations;
        } catch (e) {
          print(e.toString());
          return <Convocation>[];
        }
      } else {
        return <Convocation>[];
      }
    } catch (e) {
      print(e.toString());
      return <Convocation>[];
    }
  }

  static Future<List<Convocation>> getParentConvocation(String code) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_PARENT_CONVOCATIONS_ACTION;
      map['code'] = code;

      final response = await http.post(Uri.parse(ROOT), body: map);
      // print("get parent convocation Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Convocation> convocations =
              parseConvocationResponse(response.body);
          return convocations;
        } catch (e) {
          print(e.toString());
          return <Convocation>[];
        }
      } else {
        return <Convocation>[];
      }
    } catch (e) {
      print(e.toString());
      return <Convocation>[];
    }
  }

  static Future<List<Classe>> getAllClasses() async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_ALL_CLASSES_ACTION;
      final response = await http.post(Uri.parse(ROOT), body: map);
      // print("get Year Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Classe> classes = parseClassResponse(response.body);
          return classes;
        } catch (e) {
          print("error is here");
          print(e.toString());
          return <Classe>[];
        }
      } else {
        return <Classe>[];
      }
    } catch (e) {
      // print(e.toString());
      return <Classe>[];
    }
  }

  static List<Year> parseYearResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Year>((json) => Year.fromJson(json)).toList();
  }

  static List<Convocation> parseConvocationResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed
        .map<Convocation>((json) => Convocation.fromJson(json))
        .toList();
  }

  static List<SequenceEvaluation> parseSequenceEvaluationResponse(
      String responseBody) {
    final decoded = json.decode(responseBody);
    if (decoded is! List) {
      throw const FormatException('Expected a sequence list');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SequenceEvaluation.fromJson)
        .where((sequence) => sequence.LibelleEvaluation.trim().isNotEmpty)
        .toList();
  }

  static List<Classe> parseClassResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Classe>((json) => Classe.fromJson(json)).toList();
  }
}
