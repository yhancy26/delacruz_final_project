<?php


namespace App\Http\Requests;


use App\Models\Student;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;


class StoreStudentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }


    public function rules(): array
    {
        return [
            'first_name' => ['required', 'string', 'max:255'],
            'last_name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:students,email'],
            'student_number' => ['required', 'string', 'max:255', 'unique:students'],
            'year_level' => ['required', 'integer', Rule::in(array_keys(Student::yearLevels()))],
            'course' => ['required', 'string', 'max:255'],
        ];
    }
}



