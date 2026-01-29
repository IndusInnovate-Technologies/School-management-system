from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.db.models import Q
import re
import random
import os

# Import modules to access data
from management_admin.models import Student
from teacher.models import Grade, Attendance, Fee
from student_parent.models import Parent

class AIChatView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        query = request.data.get('query', '').lower().strip()
        
        if not query:
            return Response({'response': "Please ask me something!"})

        # 1. Identify context (School Data vs General)
        response_text = ""
        
        # --- SCHOOL DATA HANDLERS ---
        
        # Fees / Due
        if 'fee' in query or 'due' in query or 'payment' in query:
            response_text = self.get_fee_info(user)
            
        # Grades / Marks / Results
        elif 'grade' in query or 'mark' in query or 'result' in query or 'score' in query:
            response_text = self.get_grade_info(user)
            
        # Attendance / Absent / Present
        elif 'attendance' in query or 'present' in query or 'absent' in query:
            response_text = self.get_attendance_info(user)
            
        # Profile / Info
        elif 'profile' in query or 'my info' in query:
             response_text = self.get_profile_info(user)

        # --- GENERAL KNOWLEDGE REPLIES (Simulating ChatGPT) ---
        
        elif 'independence day' in query:
            response_text = ("Independence Day is celebrated annually on August 15th in India. "
                             "It marks the end of British rule in 1947 and the establishment of a free and independent Indian nation. "
                             "The Prime Minister hoists the national flag at the Red Fort in Delhi and delivers a speech.")
        
        elif 'republic day' in query:
             response_text = ("Republic Day is celebrated on January 26th. It honors the date on which the Constitution of India came into effect in 1950.")
        
        elif 'school' in query and 'open' in query:
             response_text = "The school is typically open from 8:00 AM to 3:00 PM, Monday through Saturday."

        # --- OPENAI INTEGRATION (Optional) ---
        # If no specific rule matched, try to call OpenAI if key exists.
        if not response_text:
            api_key = os.getenv('OPENAI_API_KEY')
            if api_key:
                try:
                    import openai
                    openai.api_key = api_key
                    # Simple Chat Completion
                    completion = openai.chat.completions.create(
                        model="gpt-3.5-turbo",
                        messages=[
                            {"role": "system", "content": "You are a helpful assistant for a school management app."},
                            {"role": "user", "content": query}
                        ]
                    )
                    response_text = completion.choices[0].message.content
                except Exception as e:
                    response_text = "I'm having trouble connecting to my brain right now. Please try again later."
            else:
                # Fallback conversational filler
                greetings = ['hello', 'hi', 'hey', 'good morning', 'good evening']
                if any(x in query for x in greetings):
                    response_text = "Hello! I am your School AI Assistant. Ask me about grades, attendance, or fees!"
                else:
                    response_text = ("I am an AI focused on your school data. "
                                     "I can tell you about your **grades**, **attendance**, or **pending fees**. "
                                     "For general questions like '${query}', please configure my OpenAI Key.")

        return Response({'response': response_text})

    def get_student(self, user):
        # Helper to find the student object linked to this user
        try:
            if hasattr(user, 'student_profile'): # If user is student
                 return user.student_profile
            # If user is parent, get first child (simplification)
            parent = Parent.objects.filter(user=user).first()
            if parent and parent.students.exists():
                return parent.students.first()
            # If user is also in Student table directly
            return Student.objects.filter(user=user).first()
        except:
            return None

    def get_fee_info(self, user):
        student = self.get_student(user)
        if not student:
            return "I couldn't find your student record to check fees."
            
        fees = Fee.objects.filter(student=student, status='pending')
        if not fees.exists():
            return "You have no pending fees! Great job."
        
        total = sum(f.amount for f in fees)
        count = fees.count()
        return f"You have {count} pending fee records totaling ₹{total}. Please make payment soon."

    def get_grade_info(self, user):
        student = self.get_student(user)
        if not student:
            return "I couldn't find your student record."
            
        # Get 3 most recent grades
        grades = Grade.objects.filter(student=student).order_by('-date_recorded')[:3]
        if not grades.exists():
            return "I assume you are doing well, but I don't see any recent grades uploaded."
            
        msg = "Here are your recent results: "
        for g in grades:
            msg += f"{g.subject} ({g.marks_obtained}/{g.total_marks}), "
        return msg

    def get_attendance_info(self, user):
        student = self.get_student(user)
        if not student:
            return "No student record found."
            
        # Last 5 days
        attendance = Attendance.objects.filter(student=student).order_by('-date')[:5]
        if not attendance.exists():
             return "No attendance records found recently."
             
        present = attendance.filter(status='present').count()
        total = attendance.count()
        return f"In the last {total} recorded days, you were present for {present} of them."

    def get_profile_info(self, user):
        student = self.get_student(user)
        if not student:
             return f"You are logged in as {user.username}."
        return f"Student Profile: {student.first_name} {student.last_name} (Class {student.class_name})."
