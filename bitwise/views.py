from django.shortcuts import render
from .forms import NumberForm
from pymongo import MongoClient
import os

def index(request):
    if request.method == 'POST':
        form = NumberForm(request.POST)
        if form.is_valid():
            # Get cleaned data
            a = form.cleaned_data['a']
            b = form.cleaned_data['b']
            c = form.cleaned_data['c']
            d = form.cleaned_data['d']
            e = form.cleaned_data['e']
            
            # Create list with values
            original_values = [a, b, c, d, e]
            
            # Process data
            # Check if all inputs are numeric (already done by form validation)
            
            # Warn if any values are negative
            negative_values = [val for val in original_values if val < 0]
            negative_warning = "Warning: Some values are negative!" if negative_values else ""
            
            # Calculate average and check if it's > 50
            average = sum(original_values) / len(original_values)
            average_check = average > 50
            
            # Count positive values
            positive_count = sum(1 for val in original_values if val > 0)
            
            # Use bitwise check to determine if positive count is even or odd
            is_even = (positive_count & 1) == 0
            parity = "even" if is_even else "odd"
            
            # Create a new list with values > 10, sort it
            values_gt_10 = sorted([val for val in original_values if val > 10])
            
            # Prepare results
            results = {
                'original_values': original_values,
                'negative_warning': negative_warning,
                'average': average,
                'average_check': average_check,
                'positive_count': positive_count,
                'parity': parity,
                'values_gt_10': values_gt_10,
            }
            
            # Save to MongoDB
            try:
                # Connect to MongoDB
                client = MongoClient(host=os.environ.get('MONGODB_HOST', 'localhost'), 
                                    port=int(os.environ.get('MONGODB_PORT', 27017)))
                db = client[os.environ.get('MONGODB_DB', 'assignment8')]
                collection = db[os.environ.get('MONGODB_COLLECTION', 'results')]
                
                # Prepare document
                document = {
                    'input': original_values,
                    'output': results
                }
                
                # Insert document
                collection.insert_one(document)
                
                # Close connection
                client.close()
                
                mongo_status = "Data saved to MongoDB successfully!"
            except Exception as e:
                mongo_status = f"Error saving to MongoDB: {str(e)}"
            
            # Render results
            return render(request, 'bitwise/results.html', {'results': results, 'mongo_status': mongo_status})
    else:
        form = NumberForm()
    
    return render(request, 'bitwise/index.html', {'form': form})