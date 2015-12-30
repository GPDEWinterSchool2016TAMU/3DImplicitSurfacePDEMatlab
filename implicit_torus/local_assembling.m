function [ lstiff,lrhs ] = local_assembling( v,d,h, quad_degree )
% Local assembling routine (linear element)
% for a cell intersects with the narrow band with size h
%
% input:
%   v: vertex list (4 by 4 matrix)
%   d: distance function evaluation on each vertex (1 by 4 vector)
%   h: size for narrow band (usually mesh size)
%   quad_degree: degree of quadrature to apply on each tetrahedra
% output:
%   lstiff: local stiffness matrix (4 by 4 for linear case)
%   lrhs: local right hand side (1 by 4 for linear case)
%
% We want to compute: for each cell \tao
%
% lstiff(j,k)= int_{\tao\cap D_h}(\nabla\phi_k\cdot\nabla\phi_j
%                                 +\phi_k\phi_j)|\nabla I_h\Phi| dx
% and
%
% lrhs(j)= int_{\tao\cap D_h} f^e \phi_j|\nabla I_h\Phi| dx
% 
% where D_h is the narrow band, phi_j are shape functions,
% I_h\Phi is the interpolation of the level set function and
% f^e is the extension of the right hand side function.
% To do this, we apply quadrature rule for each subdivision of 
% the integral domain \tao\cap D_h.
%
% Wenyu Lei
% Dec 29, 2015

if (nargin < 4)
    quad_degree = 2;
end

% Initialization
lstiff=zeros(4,4);
lrhs=zeros(1,4);

% Loop through the subdivision of the integral domain.
for subT = subdivide(v',d,h)
    
    % Get the quadarature info for each subdivision.
    points_list = subT{1}'; % extract the vertices
    [nq,q,w]=volquad(points_list, quad_degree);
    
    % preallocate rhs values at q
    rhs_vals_at_q = rhs_eval(q); % [4x1]
    
    % Add the increament for local stiffenss and right hand side on 
    % each quadrature point.
    for q_point = 1:nq
        shape_values_at_q_point=zeros(1,4);
        shape_grads_at_q_point=zeros(4,3);
        
        for j = 1:4
            shape_values_at_q_point(j)=eval_basis_value(q(q_point,:),j,v);
            shape_grads_at_q_point(j,:)=eval_basis_grad(q(q_point,:),j,v);
        end
        gls_interp=grad_interp_levelset(shape_grads_at_q_point,d);
        for j = 1:4
            for k = 1:4
                %
                % S = \int (gradphi_j . gradphi_k + phi_j*phi_k) *|grad I_h d| dx
                %
                lstiff(j,k)=lstiff(j,k)...
                    +( shape_grads_at_q_point(j,:)*shape_grads_at_q_point(k,:)'...
                       +shape_values_at_q_point(j)*shape_values_at_q_point(k)...
                     )*gls_interp*w(q_point);
            end
            %
            % F = \int f*phi_j*|grad I_h d| dx
            %
            lrhs(j)=lrhs(j) + rhs_vals_at_q(q_point)*shape_values_at_q_point(j)...
                                  *gls_interp*w(q_point);
        end
    end
end

end

