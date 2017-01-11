to_link_name(frame::CartesianFrame3D) =
    Symbol("$(RigidBodyDynamics.name(frame))_(#$(frame.id))")


function load!(vis::Visualizer, frame_geometries::Associative{CartesianFrame3D, Vector{GeometryData}})
    batch(vis) do v
        delete!(v)
        for (frame, geoms) in frame_geometries
            for (i, geom) in enumerate(geoms)
                load!(v[to_link_name(frame)][Symbol("geometry$i")], geom)
            end
        end
    end
end

function draw!(vis::Visualizer, state::MechanismState)
    batch(vis) do v
        for frame in keys(state.mechanism.bodyFixedFrameToBody)
            framename = to_link_name(frame)
            if framename in keys(vis.core.tree[vis.path].children)
                framevis = v[to_link_name(frame)]
                draw!(framevis, convert(AffineMap, transform_to_root(state, frame)))
            end
        end
    end
end

"""
Construct a DrakeVisualizer.Visualizer for the given mechanism by constructing
simple geometries just from the structure of the kinematic tree. If
`show_intertias` is true, then also construct equivalent inertial ellipsoids
for every link.
"""
function Visualizer(mechanism::Mechanism, prefix=[:robot1];
                    show_inertias::Bool=false, randomize_colors::Bool=true)
    vis = Visualizer()[prefix]
    frame_geoms = create_geometry(mechanism; show_inertias=show_inertias, randomize_colors=randomize_colors)
    load!(vis, frame_geoms)
    vis
end

convert(::Type{AffineMap}, T::Transform3D) =
    AffineMap(T.rot, T.trans)

# function draw(vis::Visualizer, state::MechanismState)
#     transforms = Dict(
#         (frame, convert(AffineMap, transform_to_root(state, frame))) for frame in keys(vis.links))
#     draw(vis, transforms)
# end

inspect!(state::MechanismState, vis::Visualizer=Visualizer(mechanism)) = manipulate!(state) do state
    draw!(vis, state)
end

function inspect!(state::MechanismState;
        show_inertias::Bool=false, randomize_colors::Bool=true)
    vis = Visualizer()[:robot1]
    load!(vis, create_geometry(state.mechanism;
                               show_inertias=show_inertias,
                               randomize_colors=randomize_colors))
    inspect!(state, vis)
end

inspect(mechanism::Mechanism, args...; kwargs...) =
    inspect!(MechanismState(Float64, mechanism), args...; kwargs...)
