<?php


namespace App\Http\Controllers;


use App\Events\StudentCreated;
use App\Http\Requests\StoreStudentRequest;
use App\Http\Requests\UpdateStudentRequest;
use App\Models\Student;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;


class StudentController extends Controller
{
    public function index(): View
    {
        $students = Student::query()
            ->orderBy('last_name')
            ->orderBy('first_name')
            ->paginate(10);


        return view('students.index', compact('students'));
    }


    public function create(): View
    {
        return view('students.create');
    }


    public function store(StoreStudentRequest $request): RedirectResponse
    {
        $student = Student::create($request->validated());


        broadcast(new StudentCreated($student))->toOthers();


        return redirect()
            ->route('students.index')
            ->with('status', 'student-created');
    }


    public function edit(Student $student): View
    {
        return view('students.edit', compact('student'));
    }


    public function update(UpdateStudentRequest $request, Student $student): RedirectResponse
    {
        $student->update($request->validated());


        return redirect()
            ->route('students.index')
            ->with('status', 'student-updated');
    }


    public function destroy(Student $student): RedirectResponse
    {
        $student->delete();


        return redirect()
            ->route('students.index')
            ->with('status', 'student-deleted');
    }
}

