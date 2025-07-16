import mujoco
import mujoco.viewer

m = mujoco.MjModel.from_xml_path("/workspaces/mujoco/bebop_mjcf/textured/bebop/bebop.xml")
d = mujoco.MjData(m)

with mujoco.viewer.launch_passive(m, d) as viewer:
    with viewer.lock():
        # ativa visualização do casco convexo (colisores)
        viewer.opt.flags[mujoco.mjtVisFlag.mjVIS_CONVEXHULL] = 1
        # desativa o desenho das BVH das meshes, que corresponde à malha renderizada
        viewer.opt.flags[mujoco.mjtVisFlag.mjVIS_MESHBVH] = 0
        # opcional: wireframe e pontos de contato
        # viewer.opt.flags[mujoco.mjtVisFlag.mjVIS_WIREFRAME] = 1
        viewer.opt.flags[mujoco.mjtVisFlag.mjVIS_CONTACTPOINT] = 1

    while viewer.is_running():
        mujoco.mj_step(m, d)
        viewer.sync()
