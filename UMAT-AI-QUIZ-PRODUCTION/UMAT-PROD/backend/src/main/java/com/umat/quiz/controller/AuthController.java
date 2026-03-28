package com.umat.quiz.controller;

import com.umat.quiz.model.Student;
import com.umat.quiz.model.Lecturer;
import com.umat.quiz.repository.StudentRepository;
import com.umat.quiz.repository.LecturerRepository;
import com.umat.quiz.repository.QuizAttemptRepository;
import com.umat.quiz.security.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    private static final Pattern REF_PATTERN =
        Pattern.compile("^UMAT/[A-Z]{2,4}/\\d{2}/\\d{4}$", Pattern.CASE_INSENSITIVE);

    @Autowired private StudentRepository studentRepo;
    @Autowired private LecturerRepository lecturerRepo;
    @Autowired private QuizAttemptRepository attemptRepo;
    @Autowired private JwtUtil jwtUtil;
    @Autowired private BCryptPasswordEncoder passwordEncoder;

    // ── Student Login ─────────────────────────────────────────
    @PostMapping("/student/login")
    public ResponseEntity<?> studentLogin(@RequestBody Map<String, String> body) {
        String refNumber = body.getOrDefault("referenceNumber", "").trim().toUpperCase();

        if (!REF_PATTERN.matcher(refNumber).matches()) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Invalid reference number format. Expected: UMAT/CS/21/0042"
            ));
        }

        Optional<Student> opt = studentRepo.findByReferenceNumber(refNumber);
        if (opt.isEmpty()) {
            return ResponseEntity.status(404).body(Map.of(
                "error", "Reference number not found. Contact your department."
            ));
        }

        Student student = opt.get();
        if (!student.isActive()) {
            return ResponseEntity.status(403).body(Map.of("error", "Account deactivated."));
        }

        student.setLastLogin(LocalDateTime.now());
        studentRepo.save(student);

        long totalQuizzes = attemptRepo.findByStudentId(student.getId()).stream()
            .filter(a -> a.getStatus() != com.umat.quiz.model.QuizAttempt.AttemptStatus.IN_PROGRESS)
            .count();
        student.setTotalQuizzesTaken((int) totalQuizzes);

        String token = jwtUtil.generateStudentToken(student);
        return ResponseEntity.ok(Map.of(
            "token", token,
            "student", buildStudentProfile(student, (int) totalQuizzes)
        ));
    }

    // ── Get student profile ───────────────────────────────────
    @GetMapping("/student/profile/{id}")
    public ResponseEntity<?> getStudentProfile(@PathVariable Long id) {
        Student student = studentRepo.findById(id).orElseThrow();
        long totalQuizzes = attemptRepo.findByStudentId(id).stream()
            .filter(a -> a.getStatus() != com.umat.quiz.model.QuizAttempt.AttemptStatus.IN_PROGRESS)
            .count();
        return ResponseEntity.ok(buildStudentProfile(student, (int) totalQuizzes));
    }

    private Map<String, Object> buildStudentProfile(Student student, int totalQuizzes) {
        Map<String, Object> profile = new LinkedHashMap<>();
        profile.put("id", student.getId());
        profile.put("referenceNumber", student.getReferenceNumber());
        profile.put("fullName", student.getFullName());
        profile.put("program", student.getProgram());
        profile.put("department", student.getDepartment());
        profile.put("course", student.getCourse());
        profile.put("level", student.getLevel());
        profile.put("email", student.getEmail());
        profile.put("enrollmentDate", student.getEnrollmentDate());
        profile.put("totalQuizzesTaken", totalQuizzes);
        profile.put("lastLogin", student.getLastLogin());
        return profile;
    }

    // ── Lecturer Login ────────────────────────────────────────
    @PostMapping("/lecturer/login")
    public ResponseEntity<?> lecturerLogin(@RequestBody Map<String, String> body) {
        String username = body.getOrDefault("username", "").trim();
        String password = body.getOrDefault("password", "");

        Optional<Lecturer> opt = lecturerRepo.findByUsername(username);
        if (opt.isEmpty() || !passwordEncoder.matches(password, opt.get().getPassword())) {
            return ResponseEntity.status(401).body(Map.of("error", "Invalid credentials."));
        }

        Lecturer lecturer = opt.get();
        lecturer.setLastLogin(LocalDateTime.now());
        lecturerRepo.save(lecturer);

        return ResponseEntity.ok(Map.of(
            "token", jwtUtil.generateLecturerToken(lecturer),
            "lecturer", Map.of(
                "id", lecturer.getId(),
                "fullName", lecturer.getFullName(),
                "department", lecturer.getDepartment(),
                "email", lecturer.getEmail(),
                "username", lecturer.getUsername()
            )
        ));
    }

    // ── Lecturer: change password ─────────────────────────────
    @PostMapping("/lecturer/change-password")
    public ResponseEntity<?> changePassword(@RequestBody Map<String, String> body) {
        String username = body.getOrDefault("username", "");
        String oldPw = body.getOrDefault("oldPassword", "");
        String newPw = body.getOrDefault("newPassword", "");

        if (newPw.length() < 6)
            return ResponseEntity.badRequest().body(Map.of("error", "Password must be at least 6 characters."));

        Optional<Lecturer> opt = lecturerRepo.findByUsername(username);
        if (opt.isEmpty() || !passwordEncoder.matches(oldPw, opt.get().getPassword()))
            return ResponseEntity.status(401).body(Map.of("error", "Current password is incorrect."));

        Lecturer lec = opt.get();
        lec.setPassword(passwordEncoder.encode(newPw));
        lecturerRepo.save(lec);
        return ResponseEntity.ok(Map.of("message", "Password updated successfully."));
    }

    // ── Lecturer: update profile ──────────────────────────────
    @PutMapping("/lecturer/profile/{id}")
    public ResponseEntity<?> updateProfile(@PathVariable Long id, @RequestBody Map<String, String> body) {
        Lecturer lec = lecturerRepo.findById(id).orElseThrow();
        if (body.containsKey("fullName")) lec.setFullName(body.get("fullName"));
        if (body.containsKey("department")) lec.setDepartment(body.get("department"));
        if (body.containsKey("email")) lec.setEmail(body.get("email"));
        lecturerRepo.save(lec);
        return ResponseEntity.ok(Map.of("message", "Profile updated."));
    }
}
