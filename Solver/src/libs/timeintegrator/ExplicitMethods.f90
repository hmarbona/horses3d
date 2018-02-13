!
!////////////////////////////////////////////////////////////////////////
!
!      EcplicitMethods.f90
!      Created: 2007-10-23 09:25:32 -0400 
!      By: David Kopriva  
!
!      RK integrators for DG approximation to conservation
!      laws in 3D
!
!////////////////////////////////////////////////////////////////////////
!
MODULE ExplicitMethods
   USE SMConstants
   use HexMeshClass
   use TimeIntegratorDefinitions
   use DGSEMClass, only: ComputeQDot_FCN
   IMPLICIT NONE

   private
   public   TakeRK3Step, TakeRK5Step, TakeExplicitEulerStep
!========
 CONTAINS
!========
!
!///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
!
!  ------------------------------
!  Routine for taking a RK3 step.
!  ------------------------------
   SUBROUTINE TakeRK3Step( mesh, t, externalState, externalGradients, deltaT, ComputeTimeDerivative )
!
!     ----------------------------------
!     Williamson's 3rd order Runge-Kutta
!     ----------------------------------
!
      IMPLICIT NONE
!
!     -----------------
!     Input parameters:
!     -----------------
!
      type(HexMesh)      :: mesh
      REAL(KIND=RP)   :: t, deltaT, tk
      external        :: externalState, externalGradients
      procedure(ComputeQDot_FCN)    :: ComputeTimeDerivative
!
!     ---------------
!     Local variables
!     ---------------
!
      REAL(KIND=RP), DIMENSION(3) :: a = (/0.0_RP       , -5.0_RP /9.0_RP , -153.0_RP/128.0_RP/)
      REAL(KIND=RP), DIMENSION(3) :: b = (/0.0_RP       ,  1.0_RP /3.0_RP ,    3.0_RP/4.0_RP  /)
      REAL(KIND=RP), DIMENSION(3) :: c = (/1.0_RP/3.0_RP,  15.0_RP/16.0_RP,    8.0_RP/15.0_RP /)
      
      INTEGER :: k, id
      
      DO k = 1,3
         
         tk = t + b(k)*deltaT
         CALL ComputeTimeDerivative( mesh, tk, externalState, externalGradients )
         
!$omp parallel do schedule(runtime)
         DO id = 1, SIZE( mesh % elements )
             mesh % elements(id) % storage % G = a(k)* mesh % elements(id) % storage % G  +              mesh % elements(id) % storage % QDot
             mesh % elements(id) % storage % Q =       mesh % elements(id) % storage % Q  + c(k)*deltaT* mesh % elements(id) % storage % G
         END DO
!$omp end parallel do
         
      END DO
      
   END SUBROUTINE TakeRK3Step

   SUBROUTINE TakeRK5Step( mesh, t, externalState, externalGradients, deltaT, ComputeTimeDerivative )
!  
!        *****************************************************************************************
!           These coefficients have been extracted from the paper: "Fourth-Order 2N-Storage
!          Runge-Kutta Schemes", written by Mark H. Carpented and Christopher A. Kennedy
!        *****************************************************************************************
!
      implicit none
      type(HexMesh)      :: mesh
      REAL(KIND=RP)   :: t, deltaT, tk
      external        :: externalState, externalGradients
      procedure(ComputeQDot_FCN)    :: ComputeTimeDerivative
!
!     ---------------
!     Local variables
!     ---------------
!
      integer                    :: id, k
      integer, parameter         :: N_STAGES = 5
      real(kind=RP), parameter  :: a(N_STAGES) = [0.0_RP , -0.4178904745_RP, -1.192151694643_RP ,     -1.697784692471_RP , -1.514183444257_RP ]
      real(kind=RP), parameter  :: b(N_STAGES) = [0.0_RP , 0.1496590219993_RP , 0.3704009573644_RP , 0.6222557631345_RP , 0.9582821306748_RP ]
      real(kind=RP), parameter  :: c(N_STAGES) = [0.1496590219993_RP , 0.3792103129999_RP , 0.8229550293869_RP , 0.6994504559488_RP , 0.1530572479681_RP]

      DO k = 1, N_STAGES
         
         tk = t + b(k)*deltaT
         CALL ComputeTimeDerivative( mesh, tk, externalState, externalGradients )
         
!$omp parallel do schedule(runtime)
         DO id = 1, SIZE( mesh % elements )
            mesh % elements(id) % storage % G = a(k)*mesh % elements(id) % storage % G  +             mesh % elements(id) % storage % QDot
            mesh % elements(id) % storage % Q =      mesh % elements(id) % storage % Q  + c(k)*deltaT*mesh % elements(id) % storage % G
         END DO
!$omp end parallel do
         
      END DO

   end subroutine TakeRK5Step

   SUBROUTINE TakeExplicitEulerStep( mesh, t, externalState, externalGradients, deltaT, ComputeTimeDerivative )
!  
!        *****************************************************************************************
!           These coefficients have been extracted from the paper: "Fourth-Order 2N-Storage
!          Runge-Kutta Schemes", written by Mark H. Carpented and Christopher A. Kennedy
!        *****************************************************************************************
!
      implicit none
      type(HexMesh)      :: mesh
      REAL(KIND=RP)   :: t, deltaT, tk
      external        :: externalState, externalGradients
      procedure(ComputeQDot_FCN)    :: ComputeTimeDerivative
!
!     ---------------
!     Local variables
!     ---------------
!
      integer                    :: id, k

      CALL ComputeTimeDerivative( mesh, t, externalState, externalGradients )
         
!$omp parallel do schedule(runtime)
         DO id = 1, SIZE( mesh % elements )
            mesh % elements(id) % storage % Q = mesh % elements(id) % storage % Q  + deltaT*mesh % elements(id) % storage % QDot
         END DO
!$omp end parallel do
         
   end subroutine TakeExplicitEulerStep

!
!///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
!
END MODULE ExplicitMethods