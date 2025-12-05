--하이메타파이즈 호루스 드래곤
--Hi-Metaphys Horus Dragon
local s,id=GetID()
function s.initial_effect(c)
	--------------------------------------
	-- ■ 소환 조건
	--------------------------------------
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,
		aux.FilterBoolFunctionEx(Card.IsSetCard,0x105),1,1,          -- 메타파이즈 튜너
		aux.FilterBoolFunctionEx(Card.IsSetCard,0x105),1,99)         -- 메타파이즈 비튜너 1장 이상
	
	-- ★ "하이메타파이즈 호루스 드래곤"은 1턴에 1번밖에 특수 소환할 수 없다
	c:SetSPSummonOnce(id)

	--------------------------------------
	-- ■ ① 싱크로 소재 종류에 따른 지속효과 부여
	--------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_MATERIAL_CHECK)
	e0:SetValue(s.matcheck)
	c:RegisterEffect(e0)

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(function(e)
		return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
	end)
	e1:SetOperation(s.cont_effop)
	e1:SetLabelObject(e0)
	c:RegisterEffect(e1)

	--------------------------------------
	-- ■ ② 메타파이즈 제외 턴 → 상대 마법 발동을 1번 무효
	--------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_NEGATE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	--------------------------------------
	-- ■ 글로벌 체크 : "메타파이즈" 제외된 턴 체크
	--------------------------------------
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_REMOVE)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end
end

s.listed_series={0x105}

-------------------------------------------------------
-- ● 소재 체크 : Normal / Effect / Pendulum 판정
-------------------------------------------------------
function s.matcheck(e,c)
	local g=c:GetMaterial()
	local flag=0
	if g:IsExists(Card.IsType,1,nil,TYPE_NORMAL) then flag=flag|0x1 end
	if g:IsExists(Card.IsType,1,nil,TYPE_EFFECT) then flag=flag|0x2 end
	if g:IsExists(Card.IsType,1,nil,TYPE_PENDULUM) then flag=flag|0x4 end
	e:SetLabel(flag)
end

-------------------------------------------------------
-- ● ① 지속효과 부여
-------------------------------------------------------
function s.cont_effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local flag=e:GetLabelObject():GetLabel()

	-- ● 일반 몬스터 소재 : 자신 이외 카드 효과 무효
	if (flag & 0x1) ~= 0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCode(EFFECT_IMMUNE_EFFECT)
		e1:SetValue(function(e,te)
			return te:GetOwner() ~= e:GetOwner()
		end)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end

	-- ● 효과 몬스터 소재 : 1턴 1번 앞면 카드 효과 무효
	if (flag & 0x2) ~= 0 then
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,1))
		e2:SetCategory(CATEGORY_DISABLE)
		e2:SetType(EFFECT_TYPE_QUICK_O)
		e2:SetCode(EVENT_FREE_CHAIN)
		e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
		e2:SetRange(LOCATION_MZONE)
		e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
		e2:SetCountLimit(1)
		e2:SetTarget(s.distg)
		e2:SetOperation(s.disop)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)
	end

	-- ● 펜듈럼 몬스터 소재 : 특소 몬스터 컨트롤 획득
	if (flag & 0x4) ~= 0 then
		local e3=Effect.CreateEffect(c)
		e3:SetDescription(aux.Stringid(id,3))
		e3:SetCategory(CATEGORY_CONTROL)
		e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
		e3:SetCode(EVENT_SPSUMMON_SUCCESS)
		e3:SetRange(LOCATION_MZONE)
		e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
		e3:SetCondition(s.ctcon)
		e3:SetTarget(s.cttg)
		e3:SetOperation(s.ctop)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e3)
	end
end

-------------------------------------------------------
-- 효과 몬스터 소재 : 효과 무효
-------------------------------------------------------
function s.disfilter(c)
	return c:IsFaceup() and not c:IsDisabled()
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and s.disfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.disfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.disfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
	end
end

-------------------------------------------------------
-- 펜듈럼 소재 : 특소 몬스터 컨트롤 획득
-------------------------------------------------------
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsSummonPlayer,1,nil,1-tp)
end
function s.ctfilter(c,tp)
	return c:IsFaceup() and c:IsControler(1-tp) and c:IsAbleToChangeControler()
end
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return eg:IsContains(chkc) and s.ctfilter(chkc,tp) end
	if chk==0 then return eg:IsExists(s.ctfilter,1,nil,tp) end
	local g=eg:FilterSelect(tp,s.ctfilter,1,1,nil,tp)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.GetControl(tc,tp)
	end
end

-------------------------------------------------------
-- 글로벌 체크 : 메타파이즈 제외 여부
-------------------------------------------------------
function s.rmcheck(c,p)
	return c:IsSetCard(0x105) and c:IsControler(p)
end
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	for p=0,1 do
		if eg:IsExists(s.rmcheck,1,nil,p) then
			Duel.RegisterFlagEffect(p,id,RESET_PHASE+PHASE_END,0,1)
		end
	end
end

-------------------------------------------------------
-- ② 마법 발동 무효
-------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFlagEffect(tp,id)>0
		and ep==1-tp
		and re:IsActiveType(TYPE_SPELL)
		and Duel.IsChainNegatable(ev)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateActivation(ev)
end
