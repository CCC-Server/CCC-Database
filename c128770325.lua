local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	
	-- 융합 소재 지정
	Fusion.AddProcMix(c,true,true,128770321,128770322,128770323)

	-- 융합 소환 전용
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.fuslimit)
	c:RegisterEffect(e0)

	-- 대체 특수 소환 절차 (필드 또는 마함존의 3카드를 묘지로)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ① 직접 공격 가능
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DIRECT_ATTACK)
	c:RegisterEffect(e2)

	-- ② 융합 소환 성공 시 상대 필드 전부 제외
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.rmcon)
	e3:SetTarget(s.rmtg)
	e3:SetOperation(s.rmop)
	c:RegisterEffect(e3)

	-- ③ 묘지의 네메시스 아티팩트 융합 몬스터 장착
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_EQUIP)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,{id,2})
	e4:SetTarget(s.eqtg)
	e4:SetOperation(s.eqop)
	c:RegisterEffect(e4)

	-- ④ 다른 네메시스 아티팩트 카드의 효과 복사
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,{id,3})
	e5:SetCost(s.copycost)
	e5:SetOperation(s.copyop)
	c:RegisterEffect(e5)
end

------------------------------------------------------------
-- 특수 소환 조건
------------------------------------------------------------
function s.spfilter(c,code)
	return c:IsFaceup() and c:IsCode(code) and c:IsAbleToGraveAsCost()
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_ONFIELD,0,1,nil,128770321)
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_ONFIELD,0,1,nil,128770322)
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_ONFIELD,0,1,nil,128770323)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Group.CreateGroup()
	for _,code in ipairs({128770321,128770322,128770323}) do
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_ONFIELD,0,1,1,nil,code)
		if #sg==0 then return end
		g:Merge(sg)
	end
	Duel.SendtoGrave(g,REASON_COST)
end

------------------------------------------------------------
-- ② 융합 소환 성공 시 제외
------------------------------------------------------------
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end

------------------------------------------------------------
-- ③ 묘지의 네메시스 아티팩트 융합몬스터 장착
------------------------------------------------------------
function s.eqfilter(c)
	return c:IsSetCard(0x764) and c:IsType(TYPE_FUSION) and not c:IsForbidden()
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and s.eqfilter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_GRAVE,0,1,5,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,#g,0,0)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)
	local g=Duel.GetTargetCards(e)
	if not c:IsRelateToEffect(e) or c:IsFacedown() or #g==0 then return end
	for tc in aux.Next(g) do
		if ft<=0 then break end
		if Duel.Equip(tp,tc,c,false) then
			-- 장착 제한
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e1:SetValue(function(e,c) return c==e:GetOwner() end)
			tc:RegisterEffect(e1)
			ft=ft-1
		end
	end
end

------------------------------------------------------------
-- ④ 다른 네메시스 아티팩트 카드 효과 복사
------------------------------------------------------------
function s.copyfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x764) and not c:IsCode(id)
		and c:IsAbleToGraveAsCost() and c:GetOriginalCodeRule()
end
function s.copycost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.copyfilter,tp,LOCATION_ONFIELD,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.copyfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
	e:SetLabel(g:GetFirst():GetOriginalCodeRule())
	Duel.SendtoGrave(g,REASON_COST)
end
function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local code=e:GetLabel()
	if not c:IsRelateToEffect(e) then return end
	local cid=c:CopyEffect(code,RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END,1)

	-- 복사 효과 제거 처리
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetLabel(cid)
	e1:SetLabelObject(c)
	e1:SetCountLimit(1)
	e1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetLabelObject()
		local cid=e:GetLabel()
		c:ResetEffect(cid,RESET_COPY)
	end)
	Duel.RegisterEffect(e1,tp)
end
