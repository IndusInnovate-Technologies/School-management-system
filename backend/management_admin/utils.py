import datetime

def get_current_academic_year():
    """
    Returns the current academic year in format 'YYYY-YYYY'.
    Assumes academic year starts in April.
    """
    now = datetime.datetime.now()
    # In many schools, April starts the new session.
    # Adjust month if needed for specific regions.
    if now.month >= 4:
        return f"{now.year}-{now.year + 1}"
    else:
        return f"{now.year - 1}-{now.year}"
