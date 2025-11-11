from django import forms

class NetworkConfigForm(forms.Form):
    MAC_ADDRESS_CHOICES = [
        ('DHCPv4', 'DHCPv4'),
        ('DHCPv6', 'DHCPv6'),
    ]
    
    mac_address = forms.CharField(label='MAC Address', max_length=17)
    dhcp_version = forms.ChoiceField(label='DHCP Version', choices=MAC_ADDRESS_CHOICES)