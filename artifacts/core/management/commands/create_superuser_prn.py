import os

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand


User = get_user_model()


class Command(BaseCommand):
    help = 'Create superuser from environment variables if one does not already exist'

    def handle(self, *args, **options):
        email = os.environ.get('DJANGO_SUPERUSER_EMAIL', '').strip()
        password = os.environ.get('DJANGO_SUPERUSER_PASSWORD', '').strip()

        if not email or not password:
            self.stderr.write(
                'DJANGO_SUPERUSER_EMAIL and DJANGO_SUPERUSER_PASSWORD must be set'
            )
            return

        if User.objects.filter(is_superuser=True).exists():
            self.stdout.write('Superuser already exists, skipping')
            return

        User.objects.create_superuser(username=email, email=email, password=password)
        self.stdout.write(f'Superuser created: {email}')
