

class BusStopStudentSerializer(serializers.ModelSerializer):
    """Serializer for BusStopStudent model - handles student assignment to bus stops"""
    student_id = serializers.CharField(write_only=True, required=True, help_text='Student ID string')
    stop = serializers.CharField(write_only=True, required=True, help_text='Bus stop ID')
    
    class Meta:
        model = BusStopStudent
        fields = [
            'id', 'bus_stop', 'student', 'student_id', 'stop', 'school_id', 'school_name',
            'student_id_string', 'student_name', 'student_class', 'student_grade',
            'pickup_time', 'dropoff_time', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'bus_stop', 'student', 'school_id', 'school_name', 
            'student_id_string', 'student_name', 'student_class', 'student_grade',
            'pickup_time', 'dropoff_time', 'created_at', 'updated_at'
        ]
    
    def create(self, validated_data):
        """Create BusStopStudent instance by resolving student_id and stop_id to objects"""
        student_id_str = validated_data.pop('student_id')
        stop_id_str = validated_data.pop('stop')
        school_id = validated_data.pop('school_id', None)
        
        # Lookup student by student_id
        student_query = Student.objects.filter(student_id=student_id_str)
        if school_id:
            student_query = student_query.filter(school__school_id=school_id)
        
        student = student_query.first()
        if not student:
            raise ValidationError({
                'student_id': f'Student with ID {student_id_str} not found' + 
                             (f' in school {school_id}' if school_id else '')
            })
        
        # Lookup bus stop by stop_id
        bus_stop = BusStop.objects.filter(stop_id=stop_id_str).first()
        if not bus_stop:
            raise ValidationError({'stop': f'Bus stop with ID {stop_id_str} not found'})
        
        # Check if student is already assigned to this stop
        existing = BusStopStudent.objects.filter(bus_stop=bus_stop, student=student).first()
        if existing:
            # Return existing assignment instead of creating duplicate
            return existing
        
        # Create the assignment
        validated_data['student'] = student
        validated_data['bus_stop'] = bus_stop
        
        return super().create(validated_data)
