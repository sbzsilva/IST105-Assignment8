from django import forms

class NumberForm(forms.Form):
    a = forms.FloatField(label='Value A')
    b = forms.FloatField(label='Value B')
    c = forms.FloatField(label='Value C')
    d = forms.FloatField(label='Value D')
    e = forms.FloatField(label='Value E')