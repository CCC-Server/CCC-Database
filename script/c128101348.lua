local s,id=GetID()
function s.initial_effect(c)
	-----------------------------------------
	-- ① Declare type → Rank-Up Xyz
	-----------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY+CATEGORY_ANNOUNCE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.tg1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)

	-----------------------------------------
	-- ② GY Quick Xyz Summon
	-----------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.con2)
	e2:SetCost(s.cost2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)
end


------------------------------------------------------------
-- ① Target Xyz monster
------------------------------------------------------------
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc47) and c:IsType(TYPE_XYZ)
end

------------------------------------------------------------
-- Rank-Up 대상 Xyz 몬스터 (이름 다름)
-- ★ FIRST ARG SHOULD BE Effect → 고침
------------------------------------------------------------
function s.rkfilter(c,e,tc,tp)
	return c:IsSetCard(0xc47)
		and c:IsType(TYPE_XYZ)
		and not c:IsCode(tc:GetCode())
		and Duel.GetLocationCountFromEx(tp,tp,tc,c)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end


------------------------------------------------------------
-- ① Target
------------------------------------------------------------
function s.tg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingTarget(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>0
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil)

	Duel.Hint(HINT_SELECTMSG,tp,569)
	local ann=Duel.AnnounceType(tp)
	e:SetLabel(ann)
end


local map = {
	[0]=TYPE_MONSTER,
	[1]=TYPE_SPELL,
	[2]=TYPE_TRAP
}

------------------------------------------------------------
-- ① Operation
------------------------------------------------------------
function s.op1(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	if Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)==0 then return end

	local declared = map[e:GetLabel()]

	-- reveal 1
	Duel.ConfirmDecktop(1-tp,1)
	local top=Duel.GetDecktopGroup(1-tp,1):GetFirst()
	local matched=(top and top:IsType(declared))

	-- ★ GetMatchingGroup 수정됨 (Effect 포함시키고 클로저 사용)
	local g=Duel.GetMatchingGroup(
		function(sc)
			return s.rkfilter(sc,e,tc,tp)
		end,
		tp,LOCATION_EXTRA,0,nil
	)
	if #g==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=g:Select(tp,1,1,nil):GetFirst()
	if not sc then return end

	-- overlay transfer
	local mg=tc:GetOverlayGroup()
	if #mg>0 then Duel.Overlay(sc,mg) end
	Duel.Overlay(sc,tc)

	-- Xyz Summon
	if Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
		sc:CompleteProcedure()
	end

	-- if matched → destroy 1
	if matched and Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local dg=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
		if #dg>0 then Duel.Destroy(dg,REASON_EFFECT) end
	end
end


------------------------------------------------------------
-- ② Condition
------------------------------------------------------------
function s.con2(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end

------------------------------------------------------------
-- ② Cost
------------------------------------------------------------
function s.cost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

------------------------------------------------------------
-- ② Operation – Xyz Summon
------------------------------------------------------------
function s.op2(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	if #g==0 then return end
	if not g:IsExists(function(c) return c:IsSetCard(0xc47) end,1,nil) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local xyz=Duel.SelectMatchingCard(tp,
		function(c)
			return c:IsType(TYPE_XYZ) and c:IsSetCard(0xc47)
				and Duel.GetLocationCountFromEx(tp,tp,g,c)>0
		end,
		tp,LOCATION_EXTRA,0,1,1,nil):GetFirst()
	if not xyz then return end

	Duel.XyzSummon(tp,xyz,g)
end
