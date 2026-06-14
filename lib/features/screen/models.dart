import 'package:flutter/material.dart';

// ── Enums ───────────────────────────────────────────────────────────────────
enum AssessmentMode { targeted, discovery }

enum AssessmentType { personality, career }

// ── User & Auth Models ──────────────────────────────────────────────────────
class AuthUser {
  final String name;
  final String email;

  AuthUser({required this.name, required this.email});
}

class UserData {
  final String name;
  final int age;
  final String education;
  final String currentStatus;
  final String location;
  final String skills;
  final String? targetCareer;

  UserData({
    required this.name,
    required this.age,
    required this.education,
    required this.currentStatus,
    required this.location,
    required this.skills,
    this.targetCareer,
  });
}

// ── Assessment & Question Models ────────────────────────────────────────────
class Option {
  final String value;
  final String label;

  Option({required this.value, required this.label});
}

class Question {
  final int id;
  final String text;
  final List<Option> options;

  Question({required this.id, required this.text, required this.options});
}

// ── Career & Dashboard Models ───────────────────────────────────────────────
class CareerDetail {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String description;
  final int match;
  final List<String> reasons;
  final List<String> alternatives;

  const CareerDetail({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.description,
    required this.match,
    required this.reasons,
    required this.alternatives,
  });
}

class TestEntry {
  final int id;
  final String date;
  final String career;
  final int match;
  final String type;
  final Map<String, double> scores;

  TestEntry({
    required this.id,
    required this.date,
    required this.career,
    required this.match,
    required this.type,
    required this.scores,
  });
}

class Scores {
  final int analytical;
  final int creative;
  final int communication;
  final int organization;
  final int technical;
  final int leadership;
  final int matchScore;

  Scores({
    required this.analytical,
    required this.creative,
    required this.communication,
    required this.organization,
    required this.technical,
    required this.leadership,
    required this.matchScore,
  });
}

class RadarDataPoint {
  final String dimension;
  final int value;
  final int fullMark;

  RadarDataPoint(this.dimension, this.value, this.fullMark);
}

Widget buildDarkFeatureItem(
  IconData icon,
  String text,
  Color iconColor,
  Color bgColor,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFE5E7EB),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}
