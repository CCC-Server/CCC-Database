--네메시스 퍼펫 랭크업 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--발동
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--①,② 효과 공통 타겟 지정
function s.xyzfilter1(c,tp)
	return c:IsFaceup() and c:IsSetCard(0x763) and c:IsType(TYPE_XYZ)
		and c:GetRank()==4
		and Duel.IsExistingMatchingCard(s.rankupfilter,tp,LOCATION_EXTRA,0,1,nil,tp,c)
end
function s.rankupfilter(c,tp,mc)
	return c:IsSetCard(0x763) and c:IsType(TYPE_XYZ) and c:GetRank()>mc:GetRank()
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
end

--② 로이드 & 빅토리아 확인
function s.lvfilter(c,code)
	return c:IsFaceup() and c:IsCode(code)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	local b1=Duel.IsExistingTarget(s.xyzfilter1,tp,LOCATION_MZONE,0,1,nil,tp)
	local b2=(Duel.IsExistingTarget(s.lvfilter,tp,LOCATION_MZONE,0,1,nil,128770303)
			and Duel.IsExistingTarget(s.lvfilter,tp,LOCATION_MZONE,0,1,nil,128770302)
			and Duel.GetLocationCountFromEx(tp,tp,nil,128770301)>0)
	if chk==0 then return b1 or b2 end
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1)) -- ① or ② 선택
	elseif b1 then
		op=0
	else
		op=1
	end
	e:SetLabel(op)
	if op==0 then
		e:SetProperty(EFFECT_FLAG_CARD_TARGET)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		Duel.SelectTarget(tp,s.xyzfilter1,tp,LOCATION_MZONE,0,1,1,nil,tp)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	else
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local op=e:GetLabel()
	if op==0 then
		--① 랭크업
		local tc=Duel.GetFirstTarget()
		if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.rankupfilter,tp,LOCATION_EXTRA,0,1,1,nil,tp,tc)
		local sc=g:GetFirst()
		if sc then
			local mg=tc:GetOverlayGroup()
			if #mg>0 then
				Duel.Overlay(sc,mg)
			end
			sc:SetMaterial(Group.FromCards(tc))
			Duel.Overlay(sc,Group.FromCards(tc))
			Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
			sc:CompleteProcedure()
		end
	else
		--② 로이드 + 빅토리아 → 오르키스
		local g1=Duel.GetMatchingGroup(s.lvfilter,tp,LOCATION_MZONE,0,nil,128770303)
		local g2=Duel.GetMatchingGroup(s.lvfilter,tp,LOCATION_MZONE,0,nil,128770302)
		if #g1==0 or #g2==0 then return end
		local sg=Group.CreateGroup()
		sg:AddCard(g1:GetFirst())
		sg:AddCard(g2:GetFirst())
		local sc=Duel.GetFirstMatchingCard(function(c)
			return c:IsCode(128770301)
		end,tp,LOCATION_EXTRA,0,nil)
		if sc and Duel.GetLocationCountFromEx(tp,tp,sg,sc)>0 then
			local mg=Group.CreateGroup()
			for tc in aux.Next(sg) do
				local og=tc:GetOverlayGroup()
				if #og>0 then mg:Merge(og) end
			end
			if #mg>0 then Duel.Overlay(sc,mg) end
			sc:SetMaterial(sg)
			Duel.Overlay(sc,sg)
			for tc in aux.Next(sg) do
				Duel.SendtoGrave(tc,REASON_MATERIAL+REASON_XYZ)
			end
			Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
			sc:CompleteProcedure()
		end
	end
end
