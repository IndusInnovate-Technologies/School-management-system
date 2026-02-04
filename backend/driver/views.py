"""
Driver portal API: assigned route, stops with students, ride start/end, stop notes.
All endpoints require an authenticated user with role 'driver' and an assigned bus.
"""
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from django.utils import timezone
from management_admin.models import Driver, Bus, BusStop, BusStopStudent, BusStopAttendance


def _get_driver_bus(user):
    """Return (driver_profile, bus) or (None, None) if not a driver or no bus assigned."""
    if not user or not user.is_authenticated:
        return None, None
    if not getattr(user, 'role', None) or (user.role.name if user.role else None) != 'driver':
        return None, None
    try:
        driver = Driver.objects.select_related('bus', 'bus__school').get(user=user)
    except Driver.DoesNotExist:
        return None, None
    return driver, driver.bus


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def route(request):
    """GET /api/driver/route/ - Assigned bus and route (stops)."""
    driver, bus = _get_driver_bus(request.user)
    if not driver or not bus:
        return Response(
            {'detail': 'No assigned bus. Contact admin to assign a bus.'},
            status=status.HTTP_403_FORBIDDEN
        )
    morning_stops = bus.stops.filter(route_type='morning').order_by('stop_order')
    afternoon_stops = bus.stops.filter(route_type='afternoon').order_by('stop_order')
    # Driver name from buses table driver_name column
    driver_name = getattr(bus, 'driver_name', None) or ''
    driver_name = (driver_name if isinstance(driver_name, str) else str(driver_name)).strip()
    return Response({
        'bus_number': bus.bus_number,
        'route_name': bus.route_name,
        'start_location': bus.start_location or '',
        'end_location': bus.end_location or '',
        'driver_first_name': driver_name,
        'driver_name': driver_name,
        'school_id': bus.school.school_id if bus.school else None,
        'school_name': bus.school.school_name if bus.school else None,
        'morning_stops': [
            {
                'stop_id': s.stop_id,
                'stop_name': s.stop_name,
                'stop_address': s.stop_address or '',
                'notes': s.notes or '',
                'stop_time': s.stop_time.strftime('%H:%M') if s.stop_time else None,
                'stop_order': s.stop_order,
            }
            for s in morning_stops
        ],
        'afternoon_stops': [
            {
                'stop_id': s.stop_id,
                'stop_name': s.stop_name,
                'stop_address': s.stop_address or '',
                'notes': s.notes or '',
                'stop_time': s.stop_time.strftime('%H:%M') if s.stop_time else None,
                'stop_order': s.stop_order,
            }
            for s in afternoon_stops
        ],
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def stops_with_students(request):
    """GET /api/driver/stops/ - Stops with students (for student tracking)."""
    driver, bus = _get_driver_bus(request.user)
    if not driver or not bus:
        return Response(
            {'detail': 'No assigned bus.'},
            status=status.HTTP_403_FORBIDDEN
        )
    route_type = request.query_params.get('route_type', '').lower()  # morning | afternoon | all
    stops_qs = bus.stops.all().order_by('route_type', 'stop_order')
    if route_type in ('morning', 'afternoon'):
        stops_qs = stops_qs.filter(route_type=route_type)
    today = timezone.now().date()
    stops_list = []
    for stop in stops_qs:
        students = BusStopStudent.objects.filter(bus_stop=stop).select_related('student')
        students_data = []
        for ss in students:
            st = ss.student
            att = BusStopAttendance.objects.filter(
                bus_stop_student=ss, attendance_date=today
            ).first()
            students_data.append({
                'id': str(ss.id),
                'student_id_string': ss.student_id_string or (st.student_id if st else '') or '',
                'student_name': ss.student_name or '',
                'student_class': ss.student_class or '',
                'student_section': ss.student_section or '',
                'pickup_time': ss.pickup_time.strftime('%H:%M') if ss.pickup_time else None,
                'dropoff_time': ss.dropoff_time.strftime('%H:%M') if ss.dropoff_time else None,
                'parent_name': (st.parent_name or '') if st else '',
                'parent_phone': (st.parent_phone or '') if st else '',
                'emergency_contact': (st.emergency_contact or '') if st else '',
                'attendance_status': att.status if att else None,
            })
        stops_list.append({
            'stop_id': stop.stop_id,
            'stop_name': stop.stop_name,
            'stop_address': stop.stop_address or '',
            'notes': stop.notes or '',
            'route_type': stop.route_type,
            'stop_order': stop.stop_order,
            'stop_time': stop.stop_time.strftime('%H:%M') if stop.stop_time else None,
            'students': students_data,
        })
    return Response({'stops': stops_list}, status=status.HTTP_200_OK)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def stop_notes(request, stop_id):
    """PATCH /api/driver/stops/<stop_id>/ - Update notes for a stop."""
    driver, bus = _get_driver_bus(request.user)
    if not driver or not bus:
        return Response({'detail': 'No assigned bus.'}, status=status.HTTP_403_FORBIDDEN)
    try:
        stop = BusStop.objects.get(stop_id=stop_id, bus=bus)
    except BusStop.DoesNotExist:
        return Response({'detail': 'Stop not found.'}, status=status.HTTP_404_NOT_FOUND)
    notes = request.data.get('notes')
    if notes is None:
        return Response({'detail': 'Provide "notes" in body.'}, status=status.HTTP_400_BAD_REQUEST)
    stop.notes = notes if isinstance(notes, str) else str(notes)
    stop.save(update_fields=['notes', 'updated_at'])
    return Response({
        'stop_id': stop.stop_id,
        'notes': stop.notes,
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_attendance(request, stop_id):
    """POST /api/driver/stops/<stop_id>/attendance/ - Save present/absent for students at this stop."""
    driver, bus = _get_driver_bus(request.user)
    if not driver or not bus:
        return Response({'detail': 'No assigned bus.'}, status=status.HTTP_403_FORBIDDEN)
    try:
        stop = BusStop.objects.get(stop_id=stop_id, bus=bus)
    except BusStop.DoesNotExist:
        return Response({'detail': 'Stop not found.'}, status=status.HTTP_404_NOT_FOUND)
    date_str = request.data.get('date')
    attendance_list = request.data.get('attendance')
    if not date_str or not isinstance(attendance_list, list):
        return Response(
            {'detail': 'Provide "date" (YYYY-MM-DD) and "attendance" (list of {bus_stop_student_id, status}).'},
            status=status.HTTP_400_BAD_REQUEST
        )
    try:
        from datetime import datetime
        att_date = datetime.strptime(date_str, '%Y-%m-%d').date()
    except (ValueError, TypeError):
        return Response({'detail': 'Invalid date format. Use YYYY-MM-DD.'}, status=status.HTTP_400_BAD_REQUEST)
    updated = 0
    for item in attendance_list:
        if not isinstance(item, dict):
            continue
        bss_id = item.get('bus_stop_student_id')
        status_val = (item.get('status') or '').lower().strip()
        if status_val not in ('present', 'absent'):
            continue
        try:
            bss = BusStopStudent.objects.get(id=bss_id, bus_stop=stop)
        except (BusStopStudent.DoesNotExist, ValueError, TypeError):
            continue
        BusStopAttendance.objects.update_or_create(
            bus_stop_student=bss,
            attendance_date=att_date,
            defaults={'status': status_val}
        )
        updated += 1
    return Response({
        'stop_id': stop_id,
        'date': date_str,
        'updated': updated,
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def ride_start(request):
    """POST /api/driver/ride/start/ - Start ride (stub: returns success)."""
    driver, bus = _get_driver_bus(request.user)
    if not driver or not bus:
        return Response({'detail': 'No assigned bus.'}, status=status.HTTP_403_FORBIDDEN)
    return Response({'success': True, 'message': 'Ride started.'}, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def ride_end(request):
    """POST /api/driver/ride/end/ - End ride (stub: returns success)."""
    driver, bus = _get_driver_bus(request.user)
    if not driver or not bus:
        return Response({'detail': 'No assigned bus.'}, status=status.HTTP_403_FORBIDDEN)
    return Response({'success': True, 'message': 'Ride ended.'}, status=status.HTTP_200_OK)
