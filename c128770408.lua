-- Antique Gear Gadget Hydra
local s,id=GetID()
function s.initial_effect(c)
	-- 어드밴스 소환 (가제트 1장으로 가능)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCondition(s.sumcon)
	e0:SetOperation(s.sumop)
	c:RegisterEffect(e0)

	-- 소환 성공시 효과 부여
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetOperation(s.regop)
	c:RegisterEffect(e1)
end

-- 어드밴스 소환 조건
function s.gadgetfilter(c)
	return c:IsSetCard(0x51) and c:IsReleasable()
end
function s.sumcon(e,c,minc)
	if c==nil then return true end
	return minc==1 and Duel.CheckTribute(c,1,1,s.gadgetfilter)
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectTribute(tp,c,1,1,s.gadgetfilter)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
	local rc=g:GetFirst()
	c:SetLabelObject(rc)
end

-- 소환 성공시 릴리스 종류에 따라 효과 부여
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetLabelObject()
	if not rc then return end

	-- EARTH: 기동요새 지속 함정 세트 (세트 턴 발동 허용)
	if rc:IsSetCard(0x51) and rc:IsAttribute(ATTRIBUTE_EARTH) then
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,0))
		e1:SetCategory(CATEGORY_TOHAND)
		e1:SetType(EFFECT_TYPE_IGNITION)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCountLimit(1,{id,1})
		e1:SetTarget(s.settg)
		e1:SetOperation(s.setop)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end

	-- LIGHT: 전투 파괴 시 데미지
	if rc:IsSetCard(0x51) and rc:IsAttribute(ATTRIBUTE_LIGHT) then
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,1))
		e2:SetCategory(CATEGORY_DAMAGE)
		e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
		e2:SetCode(EVENT_BATTLE_DESTROYING)
		e2:SetCondition(aux.bdocon)
		e2:SetTarget(s.damtg)
		e2:SetOperation(s.damop)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)
	end

	-- Fortress: 전체 공격
	if rc:IsCode(3955608,42237854,128770412,128770413) then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_ATTACK_ALL)
		e3:SetValue(1)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e3)
	end
end

-- EARTH: 기동요새 세트 + 세트 턴 발동 허용
function s.setfilter(c)
	return c:IsCode(3955608,42237854,128770412,128770413) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
	end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.SSet(tp,tc)
		Duel.ConfirmCards(1-tp,tc)
		-- 세트한 턴에 발동 가능
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

-- LIGHT: 전투 파괴 시 데미지
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local bc=e:GetHandler():GetBattleTarget()
	if chk==0 then return bc and bc:IsType(TYPE_MONSTER) end
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(bc:GetAttack())
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,bc:GetAttack())
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Damage(p,d,REASON_EFFECT)
end
