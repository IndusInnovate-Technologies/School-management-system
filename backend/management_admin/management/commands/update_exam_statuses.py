"""
Management command to update examination statuses based on current time.
This can be run periodically via cron or celery.
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from management_admin.models import Examination_management


class Command(BaseCommand):
    help = 'Update examination statuses based on current time'

    def handle(self, *args, **options):
        now = timezone.now()
        updated_count = 0
        
        # Get all exams that are not completed
        exams = Examination_management.objects.exclude(Exam_Status='completed')
        
        from datetime import timedelta
        
        for exam in exams:
            # Exam_Date is a DateTimeField - use its date part and combine with Exam_Time
            exam_date = exam.Exam_Date.date() if exam.Exam_Date else None
            if not exam_date or not exam.Exam_Time:
                continue  # Skip if date or time is missing
            
            # Create combined datetime from date and time
            from datetime import datetime
            exam_datetime = datetime.combine(exam_date, exam.Exam_Time)
            exam_start = timezone.make_aware(exam_datetime)
            
            # Calculate exam end time by adding duration
            exam_end = exam_start + timedelta(minutes=exam.Exam_Duration)
            
            new_status = None
            
            # Check if exam should be ongoing
            if exam.Exam_Status == 'upcoming' and now >= exam_start and now < exam_end:
                new_status = 'ongoing'
            # Check if exam should be completed
            elif now >= exam_end:
                new_status = 'completed'
            # Check if ongoing exam should be completed
            elif exam.Exam_Status == 'ongoing' and now >= exam_end:
                new_status = 'completed'
            
            if new_status and new_status != exam.Exam_Status:
                exam.Exam_Status = new_status
                exam.save(update_fields=['Exam_Status', 'Exam_Updated_At'])
                updated_count += 1
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Updated exam "{exam.Exam_Title}" (ID: {exam.id}) '
                        f'status to {new_status}'
                    )
                )
        
        if updated_count == 0:
            self.stdout.write(self.style.SUCCESS('No exam statuses needed updating.'))
        else:
            self.stdout.write(
                self.style.SUCCESS(
                    f'Successfully updated {updated_count} exam status(es).'
                )
            )

