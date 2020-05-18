local cam = nil

local RotToQuat = function(rot)

	local pitch = math.rad(rot.x)
	local roll  = math.rad(rot.y)
	local yaw   = math.rad(rot.z)

  local cy = math.cos(yaw   * 0.5)
	local sy = math.sin(yaw   * 0.5)
	local cr = math.cos(roll  * 0.5)
	local sr = math.sin(roll  * 0.5)
	local cp = math.cos(pitch * 0.5)
	local sp = math.sin(pitch * 0.5)

	return quat(
    cy * cr * cp + sy * sr * sp, -- w
    cy * sp * cr - sy * cp * sr, -- x
	  cy * cp * sr + sy * sp * cr, -- y
	  sy * cr * cp - cy * sr * sp  -- z
  )

end

local QuatToRot = function(quat)

	local x, y, z

	local ysqr = quat.y * quat.y
	
	local t0 = 2.0 * (quat.w * quat.x + quat.y * quat.z)
	local t1 = 1.0 - 2.0 * (quat.x * quat.x + ysqr)
	x = math.deg(math.atan(t1, t0))
	
	local t2 = 2.0 * (quat.w * quat.y - quat.z * quat.x)
	local t2 = (t2 >  1.0) and  1.0 or t2
	local t2 = (t2 < -1.0) and -1.0 or t2
	y = math.deg(math.asin(t2))
	
	local t3 = 2.0 * (quat.w * quat.z + quat.x * quat.y)
	local t4 = 1.0 - 2.0 * (ysqr + quat.z * quat.z)
	z = math.deg(math.atan(t4, t3))
	
	return vector3(x, y, z)

end

local GetCamForwardVector = function(cam)

  local coords  = GetCamCoord(cam)
  local rot     = GetCamRot(cam)

  return RotToQuat(rot) * vector3(0.0, 1.0, 0.0)

end

local GetCamRightVector = function(cam)

  local coords  = GetCamCoord(cam)
  local rot     = GetCamRot(cam)
  local qrot    = quat(0.0, vector3(rot.x, rot.y, rot.z))

  return RotToQuat(rot) * vector3(1.0, 0.0, 0.0)

end

local HandleFreeCamThisFrame = function()

  DisableControlAction(0, `INPUT_SPRINT`,             true)
  DisableControlAction(0, `INPUT_HUD_SPECIAL`,        true)
  DisableControlAction(0, `INPUT_MOVE_UP_ONLY`,       true)
  DisableControlAction(0, `INPUT_FRONTEND_NAV_UP`,    true)
  DisableControlAction(0, `INPUT_MOVE_DOWN_ONLY`,     true)
  DisableControlAction(0, `INPUT_FRONTEND_NAV_DOWN`,  true)
  DisableControlAction(0, `INPUT_MOVE_LEFT_ONLY`,     true)
  DisableControlAction(0, `INPUT_FRONTEND_NAV_LEFT`,  true)
  DisableControlAction(0, `INPUT_MOVE_RIGHT_ONLY`,    true)
  DisableControlAction(0, `INPUT_FRONTEND_NAV_RIGHT`, true)
  DisableControlAction(0, `INPUT_LOOK_LR`,            true)
  DisableControlAction(0, `INPUT_LOOK_UD`,            true)

	local camCoords       = GetCamCoord(cam)
	local right, forward  = GetCamRightVector(cam), GetCamForwardVector(cam)
	local speedMultiplier = nil

  SetHdArea(camCoords.x, camCoords.y, camCoords.z, 50.0)

	if IsDisabledControlPressed(0, `INPUT_SPRINT`) then
		speedMultiplier = 8.0
	elseif IsDisabledControlPressed(0, `INPUT_HUD_SPECIAL`) then
		speedMultiplier = 0.025
	else
		speedMultiplier = 0.25
	end

	if IsDisabledControlPressed(0, `INPUT_MOVE_UP_ONLY`) then
		local newCamPos = camCoords + forward * speedMultiplier
		SetCamCoord(cam, newCamPos.x, newCamPos.y, newCamPos.z)
	end

	if IsDisabledControlPressed(0, `INPUT_MOVE_DOWN_ONLY`) then
		local newCamPos = camCoords + forward * -speedMultiplier
		SetCamCoord(cam, newCamPos.x, newCamPos.y, newCamPos.z)
	end

	if IsDisabledControlPressed(0, `INPUT_MOVE_LEFT_ONLY`) then
		local newCamPos = camCoords + right * -speedMultiplier
		SetCamCoord(cam, newCamPos.x, newCamPos.y, newCamPos.z)
	end

	if IsDisabledControlPressed(0, `INPUT_MOVE_RIGHT_ONLY`) then
		local newCamPos = camCoords + right * speedMultiplier
		SetCamCoord(cam, newCamPos.x, newCamPos.y, newCamPos.z)
	end

	local xMagnitude = GetDisabledControlNormal(0, `INPUT_LOOK_LR`);
	local yMagnitude = GetDisabledControlNormal(0, `INPUT_LOOK_UD`);
	local camRot     = GetCamRot(cam)

	local x = camRot.x - yMagnitude * 10
	local y = camRot.y
	local z = camRot.z - xMagnitude * 10

	if x < -75.0 then
		x = -75.0
	end

	if x > 100.0 then
		x = 100.0
	end

  SetCamRot(cam, x, y, z, 0)

end

local ToggleFreecam = function()
  
  if cam == nil then

    local coords = GetEntityCoords(PlayerPedId())

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, GetGameplayCamFov(), false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, 0, 0)

  else

    local coords = GetCamCoord(cam)

    DestroyCam(cam, false)
    cam = nil

    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, false)

    ClearHdArea()

  end

end

local GetPos = function()

  if cam == nil then

    local pos = GetEntityCoords(PlayerPedId())
    TriggerEvent('chatMessage', string.format('%f, %f, %f', pos.x, pos.y, pos.z))

  else

    local pos = GetCamCoord(cam)
    TriggerEvent('chatMessage', string.format('%f, %f, %f', pos.x, pos.y, pos.z))

  end

end

RegisterNetEvent('freecam:toggle')
AddEventHandler('freecam:toggle', ToggleFreecam)

RegisterNetEvent('freecam:pos')
AddEventHandler('freecam:pos', GetPos)

DestroyAllCams(false)

CreateThread(function()
  while true do

    if cam == nil then
      Wait(250)
    else
      HandleFreeCamThisFrame()
      Wait(0)
    end

  end
end)