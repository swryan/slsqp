!*******************************************************************************
!> author: Jacob Williams
!
!  Tests for the [[slsqp_module]].

    program slsqp_test

    use slsqp_module
    use slsqp_kinds

    implicit none

    integer,parameter               :: n = 2                    !! number of optimization variables
    integer,parameter               :: m = 1                    !! total number of constraints
    integer,parameter               :: meq = 0                  !! number of equality constraints
    integer,parameter               :: max_iter = 100           !! maximum number of allowed iterations
    real(wp),dimension(n),parameter :: xl = [-1.0_wp, -1.0_wp]  !! lower bounds
    real(wp),dimension(n),parameter :: xu = [ 1.0_wp,  1.0_wp]  !! upper bounds
    real(wp),parameter              :: acc = 1.0e-8_wp          !! tolerance
    integer,parameter               :: linesearch_mode = 1      !! use inexact linesearch.

    type(slsqp_solver)    :: solver      !! instantiate an slsqp solver
    real(wp),dimension(n) :: x           !! optimization variable vector
    integer               :: istat       !! for solver status check
    logical               :: status_ok   !! for initialization status check
    integer               :: iterations  !! number of iterations by the solver

    x = [0.1_wp, 0.1_wp] !initial guess

    call solver%initialize(n,m,meq,max_iter,acc,rosenbrock_func,rosenbrock_grad,&
                            xl,xu,linesearch_mode=linesearch_mode,status_ok=status_ok,&
                            report=report_iteration)
                            !alphamin=0.1_wp, alphamax=0.5_wp) !to limit search steps

    if (status_ok) then
        call solver%optimize(x,istat,iterations)
        write(*,*) ''
        write(*,*) 'solution   :', x
        write(*,*) 'istat      :', istat
        write(*,*) 'iterations :', iterations
        write(*,*) ''
    else
        error stop 'error calling slsqp.'
    end if

    !solution:  x1 = 0.78641515097183889
    !           x2 = 0.61769831659541152
    !           f  = 4.5674808719160388E-002
    !           c  = 2.8654301154062978E-012

    contains

    subroutine rosenbrock_func(me,x,f,c)
        !! Rosenbrock function
        !!
        !! Minimize the Rosenbrock function: \( f(x) = 100 (x_2 - x_1)^2 + (1 - x_1)^2 \),
        !! subject to the inequality constraint: \( x_1^2 + x_2^2 \le 1 \).
        !!
        !! see: http://www.mathworks.com/help/optim/ug/example-nonlinear-constrained-minimization.html
        implicit none
        class(slsqp_solver),intent(inout) :: me
        real(wp),dimension(:),intent(in)  :: x      !! optimization variable vector
        real(wp),intent(out)              :: f      !! value of the objective function
        real(wp),dimension(:),intent(out) :: c      !! the constraint vector `dimension(m)`,
                                                    !! equality constraints (if any) first.

        f = 100.0_wp*(x(2) - x(1)**2)**2 + (1.0_wp - x(1))**2  !objective function
        c(1) = 1.0_wp - x(1)**2 - x(2)**2  !equality constraint (>=0)

    end subroutine rosenbrock_func

    subroutine rosenbrock_grad(me,x,g,a)
        !! gradients for [[rosenbrock_func]].
        implicit none
        class(slsqp_solver),intent(inout)   :: me
        real(wp),dimension(:),intent(in)    :: x    !! optimization variable vector
        real(wp),dimension(:),intent(out)   :: g    !! objective function partials w.r.t x `dimension(n)`
        real(wp),dimension(:,:),intent(out) :: a    !! gradient matrix of constraints w.r.t. x `dimension(m,n)`

        g(1) = -400.0_wp*(x(2)-x(1)**2)*x(1) - 2.0_wp*(1.0_wp-x(1))  !df/x1
        g(2) = 200.0_wp*(x(2) - x(1)**2)                             !df/x2

        a(1,1) = -2.0_wp*x(1)     ! dc/dx1
        a(1,2) = -2.0_wp*x(2)     ! dc/dx2

    end subroutine rosenbrock_grad

    subroutine report_iteration(me,iter,x,f,c)
        use, intrinsic :: iso_fortran_env, only: output_unit
        !! report an iteration (print to the console).
        implicit none
        class(slsqp_solver),intent(inout) :: me
        integer,intent(in)                :: iter
        real(wp),dimension(:),intent(in)  :: x
        real(wp),intent(in)               :: f
        real(wp),dimension(:),intent(in)  :: c

        !write a header:
        if (iter==0) then
            write(output_unit,'(*(A20,1X))') 'iteration', 'x(1)', 'x(2)', 'f(1)', 'c(1)'
        end if

        !write the iteration data:
        write(output_unit,'(I20,1X,(*(F20.16,1X)))') iter,x,f,c

    end subroutine report_iteration

    end program slsqp_test
!*******************************************************************************
