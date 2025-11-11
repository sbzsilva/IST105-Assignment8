from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('leases/', views.view_leases, name='view_leases'),
]