# Generated manually for changing Bus primary key from bus_id to bus_number

from django.db import migrations, models
import django.db.models.deletion


def migrate_bus_data_forward(apps, schema_editor):
    """Data migration: Ensure all buses have unique bus_numbers before making it primary key"""
    Bus = apps.get_model('management_admin', 'Bus')
    
    # Check for duplicate bus_numbers and null values
    buses = Bus.objects.all()
    bus_numbers = set()
    for bus in buses:
        if not bus.bus_number or bus.bus_number.strip() == '':
            # Generate a default bus number if empty
            bus.bus_number = f"BUS-{bus.bus_id}"
            bus.save()
        elif bus.bus_number in bus_numbers:
            # If duplicate, append a suffix
            counter = 1
            new_number = f"{bus.bus_number}_{counter}"
            while Bus.objects.filter(bus_number=new_number).exists():
                counter += 1
                new_number = f"{bus.bus_number}_{counter}"
            bus.bus_number = new_number
            bus.save()
        bus_numbers.add(bus.bus_number)


def migrate_bus_data_reverse(apps, schema_editor):
    """Reverse migration: Not implemented as this is a destructive change"""
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('super_admin', '0001_initial'),
        ('management_admin', '0019_rename_amount_to_total_amount'),
    ]

    operations = [
        # Step 1: Ensure bus_number is unique and not null
        migrations.RunPython(migrate_bus_data_forward, migrate_bus_data_reverse),
        
        # Step 2: Make bus_number non-nullable and ensure it's unique
        migrations.AlterField(
            model_name='bus',
            name='bus_number',
            field=models.CharField(
                max_length=100,
                unique=True,
                help_text='Unique bus number/identifier',
            ),
        ),
        
        # Step 3: Use raw SQL to handle the entire foreign key and primary key change
        migrations.RunSQL(
            sql="""
                DO $$
                DECLARE
                    fk_constraint_name TEXT;
                    bus_stop_col_name TEXT;
                BEGIN
                    -- Find the foreign key column name in bus_stops
                    SELECT column_name INTO bus_stop_col_name
                    FROM information_schema.columns
                    WHERE table_name = 'bus_stops' 
                    AND (column_name = 'bus_id' OR column_name = 'bus')
                    LIMIT 1;
                    
                    -- Drop foreign key constraint if it exists
                    SELECT tc.constraint_name INTO fk_constraint_name
                    FROM information_schema.table_constraints tc
                    JOIN information_schema.key_column_usage kcu 
                        ON tc.constraint_name = kcu.constraint_name
                    WHERE tc.table_name = 'bus_stops' 
                    AND tc.constraint_type = 'FOREIGN KEY'
                    AND kcu.column_name = COALESCE(bus_stop_col_name, 'bus_id')
                    LIMIT 1;
                    
                    IF fk_constraint_name IS NOT NULL THEN
                        EXECUTE 'ALTER TABLE bus_stops DROP CONSTRAINT IF EXISTS ' || quote_ident(fk_constraint_name);
                    END IF;
                    
                    -- Add temporary bus_number column to bus_stops if it doesn't exist
                    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                                   WHERE table_name='bus_stops' AND column_name='bus_number_temp') THEN
                        ALTER TABLE bus_stops ADD COLUMN bus_number_temp VARCHAR(100);
                    END IF;
                    
                    -- Populate bus_number_temp
                    IF bus_stop_col_name IS NOT NULL THEN
                        EXECUTE format('
                            UPDATE bus_stops 
                            SET bus_number_temp = (
                                SELECT bus_number 
                                FROM buses 
                                WHERE buses.bus_id::text = bus_stops.%I::text
                            )', bus_stop_col_name);
                    END IF;
                    
                    -- Drop old bus_id column if it exists
                    IF bus_stop_col_name IS NOT NULL AND bus_stop_col_name != 'bus_number_temp' THEN
                        EXECUTE 'ALTER TABLE bus_stops DROP COLUMN IF EXISTS ' || quote_ident(bus_stop_col_name);
                    END IF;
                    
                    -- Drop bus_number if it already exists (from partial migration)
                    IF EXISTS (SELECT 1 FROM information_schema.columns 
                               WHERE table_name='bus_stops' AND column_name='bus_number') THEN
                        ALTER TABLE bus_stops DROP COLUMN bus_number;
                    END IF;
                    
                    -- Rename bus_number_temp to bus_number
                    IF EXISTS (SELECT 1 FROM information_schema.columns 
                               WHERE table_name='bus_stops' AND column_name='bus_number_temp') THEN
                        ALTER TABLE bus_stops RENAME COLUMN bus_number_temp TO bus_number;
                    END IF;
                END $$;
            """,
            reverse_sql=migrations.RunSQL.noop,
        ),
        
        # Step 4: Remove bus_id field from Bus model and make bus_number primary key
        # Use SeparateDatabaseAndState to handle database changes manually
        migrations.SeparateDatabaseAndState(
            database_operations=[
                # Database operations: drop bus_id column and make bus_number primary key
                migrations.RunSQL(
                    sql="""
                        -- Drop bus_id column from buses table if it exists
                        DO $$
                        BEGIN
                            IF EXISTS (SELECT 1 FROM information_schema.columns 
                                       WHERE table_name='buses' AND column_name='bus_id') THEN
                                -- First drop primary key constraint if bus_id is the primary key
                                ALTER TABLE buses DROP CONSTRAINT IF EXISTS buses_pkey;
                                -- Drop the bus_id column
                                ALTER TABLE buses DROP COLUMN bus_id;
                                -- Make bus_number the primary key
                                ALTER TABLE buses ADD PRIMARY KEY (bus_number);
                            END IF;
                        END $$;
                    """,
                    reverse_sql=migrations.RunSQL.noop,
                ),
            ],
            state_operations=[
                # State operations: update model state
                # Commenting out RemoveField for bus_id since 0001_initial already has bus_number as PK
                # migrations.RemoveField(
                #     model_name='bus',
                #     name='bus_id',
                # ),
                migrations.AlterField(
                    model_name='bus',
                    name='bus_number',
                    field=models.CharField(
                        max_length=100,
                        primary_key=True,
                        help_text='Unique bus number/identifier (Primary Key)',
                    ),
                ),
            ],
        ),
        
        # Step 6: Update BusStop model to use bus_number as foreign key
        migrations.SeparateDatabaseAndState(
            database_operations=[
                # Database operations: add foreign key constraint on bus_number
                migrations.RunSQL(
                    sql="""
                        -- Add foreign key constraint on bus_number if it doesn't exist
                        DO $$
                        BEGIN
                            IF NOT EXISTS (
                                SELECT 1 FROM information_schema.table_constraints 
                                WHERE constraint_name = 'bus_stops_bus_number_fkey'
                                AND table_name = 'bus_stops'
                            ) THEN
                                ALTER TABLE bus_stops 
                                ADD CONSTRAINT bus_stops_bus_number_fkey 
                                FOREIGN KEY (bus_number) REFERENCES buses(bus_number) ON DELETE CASCADE;
                            END IF;
                        END $$;
                    """,
                    reverse_sql=migrations.RunSQL.noop,
                ),
            ],
            state_operations=[
                # State operations: update model state
                migrations.AlterField(
                    model_name='busstop',
                    name='bus',
                    field=models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name='stops',
                        to='management_admin.bus',
                        db_column='bus_number',
                    ),
                ),
            ],
        ),
    ]
